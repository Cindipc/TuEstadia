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
      );
}