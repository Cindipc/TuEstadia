import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_data.dart';
import 'firebase_bootstrap.dart';
import 'models/chapter.dart';
import 'models/course.dart';
import 'models/forum_post.dart';
import 'models/project.dart';
import 'repositories/forum_repository.dart';
import 'repositories/library_repository.dart';
import 'repositories/project_repository.dart';

/// Resultado del sembrado de datos de prueba en Firestore.
enum SeedStatus { success, unavailable, permissionDenied, error }

class SeedResult {
  const SeedResult(this.status, [this.message]);

  final SeedStatus status;
  final String? message;
}

/// Copia los datos de [DemoData] a Firestore.
///
/// Solo escribe en las colecciones que estén vacías, así que es seguro
/// ejecutarlo varias veces. Requiere que las reglas de Firestore permitan
/// escritura al usuario autenticado.
class SeedService {
  SeedService._();

  static const List<String> _collections = [
    ProjectRepository.collectionName,
    LibraryRepository.coursesCollection,
    LibraryRepository.chaptersCollection,
    ForumRepository.collectionName,
  ];

  static Future<SeedResult> seedDemoData() async {
    if (!FirebaseBootstrap.isAvailable) {
      return const SeedResult(
        SeedStatus.unavailable,
        'Firebase no está disponible: la app corre en modo demo.',
      );
    }

    final firestore = FirebaseFirestore.instance;
    try {
      final existing = await Future.wait(
        _collections.map((name) => firestore.collection(name).limit(1).get()),
      );
      final isEmpty = <String, bool>{
        for (var i = 0; i < _collections.length; i++)
          _collections[i]: existing[i].docs.isEmpty,
      };

      if (isEmpty.values.every((empty) => !empty)) {
        return const SeedResult(
          SeedStatus.success,
          'Las colecciones ya tienen datos; no se duplicó nada.',
        );
      }

      final batch = firestore.batch();
      final now = DateTime.now();

      if (isEmpty[ProjectRepository.collectionName]!) {
        for (var index = 0; index < DemoData.projects.length; index++) {
          final ProjectModel project = DemoData.projects[index];
          batch.set(
            firestore
                .collection(ProjectRepository.collectionName)
                .doc(project.id),
            {
              ...project.toMap(),
              'createdAt': now.subtract(Duration(hours: index * 7)),
            },
          );
        }
      }

      if (isEmpty[LibraryRepository.coursesCollection]!) {
        for (final CourseModel course in DemoData.courses) {
          batch.set(
            firestore
                .collection(LibraryRepository.coursesCollection)
                .doc(course.id),
            course.toMap(),
          );
        }
      }

      if (isEmpty[LibraryRepository.chaptersCollection]!) {
        for (final ChapterModel chapter in DemoData.chapters) {
          batch.set(
            firestore
                .collection(LibraryRepository.chaptersCollection)
                .doc(chapter.id),
            chapter.toMap(),
          );
        }
      }

      if (isEmpty[ForumRepository.collectionName]!) {
        for (var index = 0; index < DemoData.posts.length; index++) {
          final ForumPostModel post = DemoData.posts[index];
          batch.set(
            firestore.collection(ForumRepository.collectionName).doc(post.id),
            {
              ...post.toMap(),
              'createdAt': now.subtract(Duration(hours: index * 5)),
            },
          );
        }
      }

      await batch.commit();
      return const SeedResult(
        SeedStatus.success,
        'Datos de prueba cargados en Firestore.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const SeedResult(
          SeedStatus.permissionDenied,
          'Firestore rechazó la escritura (reglas de seguridad). Permite '
          'escribir a usuarios autenticados o siembra los datos desde la '
          'consola.',
        );
      }
      return SeedResult(SeedStatus.error, e.message ?? e.code);
    } catch (e) {
      return SeedResult(SeedStatus.error, e.toString());
    }
  }
}
