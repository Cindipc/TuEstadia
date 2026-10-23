import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String id;
  final String title;
  final String tech;
  final String imageUrl;
  final String authorName;
  final String authorAvatar;
  final bool saved;
  final DateTime createdAt;

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
      'createdAt': createdAt,
    };
  }

  ProjectModel copyWith({bool? saved}) {
    return ProjectModel(
      id: id,
      title: title,
      tech: tech,
      imageUrl: imageUrl,
      authorName: authorName,
      authorAvatar: authorAvatar,
      saved: saved ?? this.saved,
      createdAt: createdAt,
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
