enum DriveFileCategory {
  folder,
  pdf,
  image,
  document,
  spreadsheet,
  presentation,
  other,
}

/// Archivo o carpeta de Google Drive.
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.size,
    this.modifiedTime,
    this.webViewLink,
    this.webContentLink,
    this.thumbnailLink,
    this.iconLink,
  });

  final String id;
  final String name;
  final String mimeType;
  final int? size;
  final DateTime? modifiedTime;
  final String? webViewLink;
  final String? webContentLink;
  final String? thumbnailLink;
  final String? iconLink;

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      mimeType: json['mimeType'] as String? ?? '',
      size: int.tryParse(json['size']?.toString() ?? ''),
      modifiedTime: DateTime.tryParse(json['modifiedTime']?.toString() ?? ''),
      webViewLink: _asUrl(json['webViewLink']),
      webContentLink: _asUrl(json['webContentLink']),
      thumbnailLink: _asUrl(json['thumbnailLink']),
      iconLink: _asUrl(json['iconLink']),
    );
  }

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';

  bool get isGoogleDoc =>
      mimeType.startsWith('application/vnd.google-apps.') && !isFolder;

  String get readableSize {
    final bytes = size;
    if (isFolder || bytes == null || bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get modifiedLabel {
    final date = modifiedTime?.toLocal();
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  DriveFileCategory get category {
    if (isFolder) return DriveFileCategory.folder;
    if (mimeType == 'application/pdf') return DriveFileCategory.pdf;
    if (mimeType.startsWith('image/')) return DriveFileCategory.image;
    if (_spreadsheetTypes.contains(mimeType)) {
      return DriveFileCategory.spreadsheet;
    }
    if (_presentationTypes.contains(mimeType)) {
      return DriveFileCategory.presentation;
    }
    if (_documentTypes.contains(mimeType)) return DriveFileCategory.document;
    return DriveFileCategory.other;
  }

  String get categoryLabel {
    switch (category) {
      case DriveFileCategory.folder:
        return 'Carpeta';
      case DriveFileCategory.pdf:
        return 'PDF';
      case DriveFileCategory.image:
        return 'Imagen';
      case DriveFileCategory.document:
        return 'Documento';
      case DriveFileCategory.spreadsheet:
        return 'Hoja de cálculo';
      case DriveFileCategory.presentation:
        return 'Presentación';
      case DriveFileCategory.other:
        return 'Archivo';
    }
  }

  String? get downloadUrl {
    if (isFolder || isGoogleDoc || id.isEmpty) return null;
    return 'https://drive.google.com/uc?export=download&id=$id';
  }

  static const Set<String> _spreadsheetTypes = {
    'application/vnd.google-apps.spreadsheet',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.oasis.opendocument.spreadsheet',
    'text/csv',
  };

  static const Set<String> _presentationTypes = {
    'application/vnd.google-apps.presentation',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.presentation',
  };

  static const Set<String> _documentTypes = {
    'application/vnd.google-apps.document',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.oasis.opendocument.text',
    'application/rtf',
    'text/plain',
  };

  static String? _asUrl(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
