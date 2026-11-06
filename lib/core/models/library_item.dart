import 'package:cloud_firestore/cloud_firestore.dart';

import 'drive_file.dart';

/// Elemento de la biblioteca personal de un usuario.
///
/// Guarda una referencia al archivo de Google Drive, no el archivo en sí.
class LibraryItemModel {
  const LibraryItemModel({
    required this.id,
    required this.ownerId,
    required this.fileId,
    required this.name,
    this.mimeType = '',
    this.size,
    this.webViewLink,
    this.thumbnailUrl,
    this.category = DriveFileCategory.other,
    this.addedAt,
  });

  final String id;
  final String ownerId;
  final String fileId;
  final String name;
  final String mimeType;
  final int? size;
  final String? webViewLink;
  final String? thumbnailUrl;
  final DriveFileCategory category;
  final DateTime? addedAt;

  bool get isImage => mimeType.startsWith('image/');

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

  String get readableSize {
    final bytes = size;
    if (bytes == null || bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  factory LibraryItemModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    return LibraryItemModel(
      id: doc.id,
      ownerId: (d['ownerId'] as String?) ?? '',
      fileId: (d['fileId'] as String?) ?? '',
      name: (d['name'] as String?) ?? 'Sin nombre',
      mimeType: (d['mimeType'] as String?) ?? '',
      size: (d['size'] as num?)?.toInt(),
      webViewLink: d['webViewLink'] as String?,
      thumbnailUrl: d['thumbnailUrl'] as String?,
      category: _categoryFromName(d['category'] as String?),
      addedAt: (d['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory LibraryItemModel.fromDriveFile({
    required String id,
    required String ownerId,
    required DriveFile file,
    DateTime? addedAt,
  }) {
    return LibraryItemModel(
      id: id,
      ownerId: ownerId,
      fileId: file.id,
      name: file.name,
      mimeType: file.mimeType,
      size: file.size,
      webViewLink: file.webViewLink,
      thumbnailUrl: file.thumbnailLink,
      category: file.category,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'fileId': fileId,
      'name': name,
      'mimeType': mimeType,
      'size': size,
      'webViewLink': webViewLink,
      'thumbnailUrl': thumbnailUrl,
      'category': category.name,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  static DriveFileCategory _categoryFromName(String? name) {
    return DriveFileCategory.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DriveFileCategory.other,
    );
  }
}
