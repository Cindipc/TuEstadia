import 'package:cloud_firestore/cloud_firestore.dart';

import '../demo_data.dart';
import '../firebase_bootstrap.dart';
import '../models/chapter.dart';
import '../models/course.dart';
import '../stream_utils.dart';

/// Acceso a las colecciones `courses` y `chapters` de Firestore.
class LibraryRepository {
  LibraryRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String coursesCollection = 'courses';
  static const String chaptersCollection = 'chapters';

  final FirebaseFirestore? _injected;

  /// Acceso perezoso: en modo demo nunca se instancia Firestore.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(coursesCollection);

  CollectionReference<Map<String, dynamic>> get _chapters =>
      _firestore.collection(chaptersCollection);

  /// Flujo de cursos del carrusel superior.
  Stream<List<CourseModel>> watchCourses() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(DemoData.courses);
    }
    return withFallback(
      _courses.snapshots().map(
        (snapshot) => snapshot.docs.map(CourseModel.fromDoc).toList(
          growable: false,
        ),
      ),
      DemoData.courses,
    );
  }

  /// Flujo de capítulos ordenados por número de capítulo.
  Stream<List<ChapterModel>> watchChapters() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(DemoData.chapters);
    }
    return withFallback(
      _chapters
          .orderBy('chapterNumber')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ChapterModel.fromDoc)
                .toList(growable: false),
          ),
      DemoData.chapters,
    );
  }

  /// Marca un capítulo como leído (progreso 1.0).
  Future<void> markChapterCompleted(ChapterModel chapter) async {
    if (!FirebaseBootstrap.isAvailable) return;
    await _chapters.doc(chapter.id).update({'progress': 1});
  }
}
