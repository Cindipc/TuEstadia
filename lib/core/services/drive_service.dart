import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/drive_config.dart';
import '../models/drive_file.dart';

/// Error de Drive con un mensaje seguro para mostrar al usuario.
///
/// Nunca incluye la API key ni la URL completa de la petición.
class DriveException implements Exception {
  const DriveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cliente de solo lectura para la API v3 de Google Drive.
class DriveService {
  DriveService({
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _apiKey = apiKey ?? DriveConfig.apiKey;

  static const String _fields =
      'nextPageToken, files(id,name,mimeType,size,modifiedTime,'
      'webViewLink,webContentLink,thumbnailLink,iconLink)';

  final http.Client _client;
  final bool _ownsClient;
  final String _apiKey;
  final Duration timeout;

  static const String _missingApiKeyMessage =
      'Falta configurar GOOGLE_DRIVE_API_KEY. Ejecuta la app con '
      '--dart-define-from-file=dart_defines.json o pasa '
      '--dart-define=GOOGLE_DRIVE_API_KEY=...';
  static const String _missingFolderMessage =
      'Falta configurar GOOGLE_DRIVE_FOLDER_ID. Ejecuta la app con '
      '--dart-define-from-file=dart_defines.json o pasa '
      '--dart-define=GOOGLE_DRIVE_FOLDER_ID=...';

  Future<List<DriveFile>> listFiles({required String folderId}) async {
    if (_apiKey.trim().isEmpty) {
      throw const DriveException(_missingApiKeyMessage);
    }
    if (folderId.trim().isEmpty) {
      throw const DriveException(_missingFolderMessage);
    }

    final files = <DriveFile>[];
    String? pageToken;

    do {
      final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'q': "'$folderId' in parents and trashed=false",
        'fields': _fields,
        'pageSize': '100',
        'orderBy': 'folder,name',
        'key': _apiKey,
        'pageToken': ?pageToken,
      });

      final response = await _get(uri);
      if (response.statusCode != 200) {
        throw DriveException(_messageForStatus(response.statusCode));
      }

      final Map<String, dynamic> payload;
      try {
        payload =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } on FormatException {
        throw const DriveException(
          'Google Drive devolvió una respuesta inesperada. Inténtalo de nuevo.',
        );
      }

      final rawFiles = payload['files'];
      if (rawFiles is List) {
        for (final item in rawFiles) {
          if (item is Map<String, dynamic>) {
            files.add(DriveFile.fromJson(item));
          }
        }
      }

      pageToken = payload['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);

    if (files.isEmpty) {
      await _ensureFolderAccessible(folderId);
    }

    return List.unmodifiable(files);
  }

  /// Comprueba que la carpeta exista y sea accesible con la API key.
  ///
  /// Sin este paso, una carpeta privada devuelve una lista vacía y la app la
  /// mostraría como "carpeta vacía" en lugar de explicar el problema.
  Future<void> _ensureFolderAccessible(String folderId) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/$folderId', {
      'fields': 'id,name,mimeType,shortcutDetails',
      'supportsAllDrives': 'true',
      'key': _apiKey,
    });

    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw DriveException(_messageForStatus(response.statusCode));
    }
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const DriveException(
        'La conexión con Google Drive tardó demasiado. Revisa tu internet e '
        'inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const DriveException(
        'No se pudo conectar con Google Drive. Revisa tu conexión a internet.',
      );
    } catch (_) {
      throw const DriveException(
        'No se pudo conectar con Google Drive. Revisa tu conexión a internet.',
      );
    }
  }

  String _messageForStatus(int statusCode) {
    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      return 'No se pudo acceder a la carpeta de Drive. Verifica que la API de '
          'Google Drive esté habilitada, que la clave no tenga restricciones '
          'incompatibles y que la carpeta sea pública.';
    }
    if (statusCode == 404) {
      return 'No se encontró la carpeta en Google Drive o no es pública. '
          'Revisa el ID y comparte la carpeta con "Cualquier persona con el '
          'enlace" (lector).';
    }
    if (statusCode == 429) {
      return 'Se alcanzó el límite de consultas de Google Drive. Espera un '
          'momento e inténtalo de nuevo.';
    }
    if (statusCode >= 500) {
      return 'Google Drive no está disponible en este momento. Inténtalo más '
          'tarde.';
    }
    return 'No se pudo cargar la carpeta de Google Drive (código '
        '$statusCode). Inténtalo de nuevo.';
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
