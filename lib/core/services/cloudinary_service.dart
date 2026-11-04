import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/forum_media.dart';

/// Resultado de una subida a Cloudinary.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.bytes,
    required this.mediaType,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  final String url;
  final String publicId;
  final String resourceType;
  final String format;
  final int bytes;
  final ForumMediaType mediaType;
  final int? width;
  final int? height;
  final String? thumbnailUrl;

  ForumMediaModel toMedia() {
    return ForumMediaModel(
      type: mediaType,
      url: url,
      thumbnailUrl: thumbnailUrl,
      publicId: publicId,
      width: width,
      height: height,
      bytes: bytes,
    );
  }
}

/// Subida de archivos a Cloudinary con un preset *unsigned*.
///
/// Configuración heredada de `fwitter_reborn`:
///   cloud: `xnnb3pfg`, preset: `fwitter_preset`.
/// Se puede sobreescribir sin tocar código:
///   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=... \
///               --dart-define=CLOUDINARY_UPLOAD_PRESET=...
class CloudinaryService {
  CloudinaryService._();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'xnnb3pfg',
  );

  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'fwitter_preset',
  );

  /// Sube bytes (funciona en móvil, escritorio y web).
  ///
  /// En web no se puede usar `dart:io`, por eso la API trabaja con bytes en
  /// lugar de `File` como la referencia.
  static Future<CloudinaryUploadResult?> uploadBytes({
    required Uint8List bytes,
    required String filename,
    ForumMediaType type = ForumMediaType.image,
    http.Client? client,
  }) async {
    if (bytes.isEmpty) return null;

    final resource = type == ForumMediaType.video ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resource/upload',
    );

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );

      final streamed = client == null
          ? await request.send()
          : await client.send(request);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        debugPrint(
          'Cloudinary ${streamed.statusCode}: ${body.length > 200 ? body.substring(0, 200) : body}',
        );
        return null;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) return null;

      final format = (json['format'] as String?)?.toLowerCase() ?? '';
      final resolvedType = type == ForumMediaType.image && format == 'gif'
          ? ForumMediaType.gif
          : type;

      return CloudinaryUploadResult(
        url: secureUrl,
        publicId: (json['public_id'] as String?) ?? '',
        resourceType: (json['resource_type'] as String?) ?? resource,
        format: format,
        bytes: (json['bytes'] as num?)?.toInt() ?? bytes.length,
        mediaType: resolvedType,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        thumbnailUrl: resolvedType == ForumMediaType.video
            ? _videoThumbnail(secureUrl)
            : null,
      );
    } catch (error) {
      debugPrint('Cloudinary: error al subir $filename → $error');
      return null;
    }
  }

  /// Miniatura del primer frame para un vídeo de Cloudinary.
  static String _videoThumbnail(String url) {
    if (!url.contains('/video/upload/')) return url;
    final withFrame = url.replaceFirst('/video/upload/', '/video/upload/so_0/');
    return withFrame.replaceFirst(RegExp(r'\.[a-zA-Z0-9]+$'), '.jpg');
  }
}
