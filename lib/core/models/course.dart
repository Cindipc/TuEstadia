import 'package:cloud_firestore/cloud_firestore.dart';

/// Curso del carrusel de la Biblioteca.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.colorValue,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Clave textual del ícono (ver `CourseIcons` en `library_page.dart`).
  final String iconKey;

  final int colorValue;
  final int gradientStart;
  final int gradientEnd;

  factory CourseModel.fromMap(String id, Map<String, dynamic> map) {
    return CourseModel(
      id: id,
      title: (map['title'] as String?) ?? 'Curso',
      subtitle: (map['subtitle'] as String?) ?? '',
      iconKey: (map['iconKey'] as String?) ?? 'code',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF38BDF8,
      gradientStart: (map['gradientStart'] as num?)?.toInt() ?? 0xFF38BDF8,
      gradientEnd: (map['gradientEnd'] as num?)?.toInt() ?? 0xFF6366F1,
    );
  }

  factory CourseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return CourseModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'gradientStart': gradientStart,
      'gradientEnd': gradientEnd,
    };
  }
}
