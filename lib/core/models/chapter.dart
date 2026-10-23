import 'package:cloud_firestore/cloud_firestore.dart';

/// Capítulo de un curso (ítem de la línea de tiempo de la Biblioteca).
class ChapterModel {
  const ChapterModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.chapterNumber,
    required this.progress,
  });

  final String id;
  final String courseId;
  final String title;
  final int chapterNumber;

  /// Progreso del capítulo, de 0.0 a 1.0.
  final double progress;

  factory ChapterModel.fromMap(String id, Map<String, dynamic> map) {
    return ChapterModel(
      id: id,
      courseId: (map['courseId'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Capítulo',
      chapterNumber: (map['chapterNumber'] as num?)?.toInt() ?? 1,
      progress: ((map['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
    );
  }

  factory ChapterModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ChapterModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'chapterNumber': chapterNumber,
      'progress': progress,
    };
  }
}
