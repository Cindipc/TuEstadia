import 'package:image_picker/image_picker.dart';

import '../models/forum_media.dart';
import 'cloudinary_service.dart';

/// Resultado de subir un archivo del compositor.
class MediaUploadOutcome {
  const MediaUploadOutcome({this.media, this.error});

  final ForumMediaModel? media;
  final String? error;

  bool get isSuccess => media != null;

  const MediaUploadOutcome.failure(String message) : this(error: message);
}

/// Prepara y sube los adjuntos del foro a Cloudinary.
class MediaUploadService {
  MediaUploadService._();

  /// Máximo de adjuntos por publicación (como Twitter).
  static const int maxItems = 4;

  /// Tamaño máximo por archivo (15 MB).
  static const int maxBytes = 15 * 1024 * 1024;

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'webm',
    'avi',
    'mkv',
  };

  static const Set<String> _gifExtensions = {'gif'};

  static ForumMediaType detectType(String filename, {String? mimeType}) {
    final mime = (mimeType ?? '').toLowerCase();
    if (mime.startsWith('video/')) return ForumMediaType.video;
    if (mime == 'image/gif') return ForumMediaType.gif;

    final extension = _extensionOf(filename);
    if (_videoExtensions.contains(extension)) return ForumMediaType.video;
    if (_gifExtensions.contains(extension)) return ForumMediaType.gif;
    return ForumMediaType.image;
  }

  static Future<MediaUploadOutcome> upload(XFile file) async {
    final name = file.name.trim().isEmpty ? 'archivo' : file.name.trim();
    final type = detectType(name, mimeType: file.mimeType);

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const MediaUploadOutcome.failure('El archivo está vacío.');
      }
      if (bytes.length > maxBytes) {
        return const MediaUploadOutcome.failure(
          'El archivo supera el límite de 15 MB.',
        );
      }

      final result = await CloudinaryService.uploadBytes(
        bytes: bytes,
        filename: name,
        type: type,
      );
      if (result == null) {
        return const MediaUploadOutcome.failure(
          'No se pudo subir el archivo a Cloudinary.',
        );
      }
      return MediaUploadOutcome(media: result.toMedia());
    } catch (error) {
      return MediaUploadOutcome(error: 'Error al subir $name: $error');
    }
  }

  /// Sube varios archivos respetando [maxItems] y devuelve solo los éxitos.
  static Future<List<MediaUploadOutcome>> uploadAll(List<XFile> files) async {
    final limited = files.take(maxItems).toList(growable: false);
    return Future.wait(limited.map(upload));
  }

  static String _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }
}
