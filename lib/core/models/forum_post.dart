import 'package:cloud_firestore/cloud_firestore.dart';

/// Publicación del foro de dudas.
class ForumPostModel {
  const ForumPostModel({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.question,
    required this.code,
    required this.likes,
    required this.replies,
    required this.saved,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String authorAvatar;
  final String question;

  /// Fragmento de código opcional (se renderiza con syntax highlighting).
  final String code;

  final int likes;
  final int replies;
  final bool saved;
  final DateTime createdAt;

  factory ForumPostModel.fromMap(String id, Map<String, dynamic> map) {
    return ForumPostModel(
      id: id,
      authorName: (map['authorName'] as String?) ?? 'Anónimo',
      authorAvatar: (map['authorAvatar'] as String?) ?? '',
      question: (map['question'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      replies: (map['replies'] as num?)?.toInt() ?? 0,
      saved: (map['saved'] as bool?) ?? false,
      createdAt: _readDate(map['createdAt']),
    );
  }

  factory ForumPostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ForumPostModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'question': question,
      'code': code,
      'likes': likes,
      'replies': replies,
      'saved': saved,
      'createdAt': createdAt,
    };
  }

  ForumPostModel copyWith({int? likes, bool? saved}) {
    return ForumPostModel(
      id: id,
      authorName: authorName,
      authorAvatar: authorAvatar,
      question: question,
      code: code,
      likes: likes ?? this.likes,
      replies: replies,
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
