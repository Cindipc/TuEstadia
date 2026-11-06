import 'package:cloud_firestore/cloud_firestore.dart';

/// Origen del elemento del feed.
enum ProjectSource { project, pin }

/// Proyecto del feed (tarjeta de la grilla principal).
class ProjectModel {
  const ProjectModel({
    required this.id,
    required this.title,
    required this.tech,
    required this.imageUrl,
    required this.authorName,
    required this.authorAvatar,
    required this.saved,
    required this.createdAt,
    this.authorId,
    this.savedBy = const [],
    this.source = ProjectSource.project,
    this.description = '',
  });

  final String id;
  final String title;
  final String tech;
  final String imageUrl;
  final String authorName;
  final String authorAvatar;

  /// Estado legacy (bool global). Se mantiene por compatibilidad.
  final bool saved;

  final DateTime createdAt;

  /// uid del autor (para el perfil).
  final String? authorId;

  /// uids de quienes guardaron el elemento.
  final List<String> savedBy;

  /// Colección de origen: `projects` o `pins`.
  final ProjectSource source;

  final String description;

  bool isSavedBy(String? uid) => uid != null && savedBy.contains(uid);

  bool isOwnedBy(String? uid) => uid != null && authorId == uid;

  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      title: (map['title'] as String?) ?? 'Proyecto sin título',
      tech: (map['tech'] as String?) ?? 'General',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      authorName: (map['authorName'] as String?) ?? 'Anónimo',
      authorAvatar: (map['authorAvatar'] as String?) ?? '',
      saved: (map['saved'] as bool?) ?? false,
      createdAt: _readDate(map['createdAt']),
      authorId: (map['authorId'] as String?)?.trim().isEmpty ?? true
          ? null
          : map['authorId'] as String?,
      savedBy: ((map['savedBy'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      source: ProjectSource.project,
      description: (map['description'] as String?) ?? '',
    );
  }

  factory ProjectModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ProjectModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'tech': tech,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'saved': saved,
      'savedBy': savedBy,
      'authorId': authorId,
      'description': description,
      'createdAt': createdAt,
    };
  }

  ProjectModel copyWith({
    bool? saved,
    List<String>? savedBy,
    bool? isSavedForView,
  }) {
    return ProjectModel(
      id: id,
      title: title,
      tech: tech,
      imageUrl: imageUrl,
      authorName: authorName,
      authorAvatar: authorAvatar,
      saved: isSavedForView ?? saved ?? this.saved,
      createdAt: createdAt,
      authorId: authorId,
      savedBy: savedBy ?? this.savedBy,
      source: source,
      description: description,
    );
  }

  /// Copia con el estado "guardado" resuelto para un usuario concreto.
  ProjectModel forUser(String? uid) {
    return copyWith(
      savedBy: savedBy,
      isSavedForView: isSavedBy(uid) || (savedBy.isEmpty && saved),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
