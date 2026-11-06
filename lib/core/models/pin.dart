import 'package:cloud_firestore/cloud_firestore.dart';

import 'project.dart';

class PinModel {
  const PinModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tech,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.createdAt,
    this.savedBy = const [],
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String tech;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final DateTime? createdAt;

  /// uids de quienes guardaron el pin (para "Guardados" del perfil).
  final List<String> savedBy;

  bool isSavedBy(String? uid) => uid != null && savedBy.contains(uid);

  factory PinModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return PinModel(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      imageUrl: (d['imageUrl'] as String?) ?? '',
      tech: (d['tech'] as String?) ?? 'Otro',
      authorId: (d['authorId'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Anónimo',
      authorAvatar: (d['authorAvatar'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      savedBy: ((d['savedBy'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  /// Convierte el pin a ProjectModel para reutilizar ProjectCard.
  ProjectModel toProject() => ProjectModel(
    id: id,
    title: title,
    tech: tech,
    imageUrl: imageUrl,
    authorName: authorName,
    authorAvatar: authorAvatar,
    saved: false,
    createdAt: createdAt ?? DateTime.now(),
    authorId: authorId.isEmpty ? null : authorId,
    savedBy: savedBy,
    source: ProjectSource.pin,
    description: description,
  );
}
