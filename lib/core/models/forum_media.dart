/// Tipo de adjunto de una publicación del foro.
enum ForumMediaType { image, video, gif }

/// Adjunto subido a Cloudinary (imagen, vídeo o GIF).
class ForumMediaModel {
  const ForumMediaModel({
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.publicId,
    this.width,
    this.height,
    this.bytes,
  });

  final ForumMediaType type;

  /// URL pública (`secure_url` de Cloudinary).
  final String url;

  /// Miniatura para vídeos (Cloudinary puede generarla cambiando la extensión).
  final String? thumbnailUrl;

  /// `public_id` de Cloudinary (útil para borrar el asset más adelante).
  final String? publicId;

  final int? width;
  final int? height;
  final int? bytes;

  bool get isVideo => type == ForumMediaType.video;
  bool get isGif => type == ForumMediaType.gif;

  factory ForumMediaModel.fromMap(Map<String, dynamic> map) {
    final url = (map['url'] as String?) ?? '';
    final rawType = (map['type'] as String?) ?? '';
    final type = ForumMediaType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => _inferType(url),
    );

    return ForumMediaModel(
      type: type,
      url: url,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      publicId: map['publicId'] as String?,
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      bytes: (map['bytes'] as num?)?.toInt(),
    );
  }

  static ForumMediaModel? tryFrom(dynamic value) {
    if (value is Map<String, dynamic>) return ForumMediaModel.fromMap(value);
    if (value is Map) {
      return ForumMediaModel.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'publicId': publicId,
      'width': width,
      'height': height,
      'bytes': bytes,
    };
  }

  static ForumMediaType _inferType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v')) {
      return ForumMediaType.video;
    }
    if (lower.endsWith('.gif')) return ForumMediaType.gif;
    return ForumMediaType.image;
  }
}
