import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'local_env.dart';

/// Configuración de Google Drive.
///
/// Orden de prioridad para cada valor:
///   1. `--dart-define` (CI / builds explícitos).
///   2. Asset `.env` (flutter_dotenv).
///   3. Archivo `.env` local en desktop/móvil (respaldo de desarrollo).
class DriveConfig {
  DriveConfig._();

  static const String _apiKeyDefine = String.fromEnvironment(
    'GOOGLE_DRIVE_API_KEY',
  );
  static const String _folderDefine = String.fromEnvironment(
    'GOOGLE_DRIVE_FOLDER_ID',
  );

  static String get apiKey => _resolve('GOOGLE_DRIVE_API_KEY', _apiKeyDefine);

  static String get rootFolderId =>
      _resolve('GOOGLE_DRIVE_FOLDER_ID', _folderDefine);

  static bool get isConfigured =>
      apiKey.trim().isNotEmpty && rootFolderId.trim().isNotEmpty;

  static String _resolve(String key, String define) {
    final fromDefine = define.trim();
    if (fromDefine.isNotEmpty) return fromDefine;

    try {
      final fromAsset = dotenv.env[key]?.trim();
      if (fromAsset != null && fromAsset.isNotEmpty) return fromAsset;
    } catch (_) {
      // dotenv no inicializado (pruebas) o limpiado: se usa el respaldo.
    }

    return (readLocalEnvValue(key) ?? '').trim();
  }
}
