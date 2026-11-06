import 'package:cloud_firestore/cloud_firestore.dart';

import '../demo_data.dart';
import '../firebase_bootstrap.dart';
import '../models/project.dart';
import '../stream_utils.dart';

/// Acceso a la colección `projects` de Firestore.
class ProjectRepository {
  ProjectRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'projects';

  final FirebaseFirestore? _injected;

  /// Acceso perezoso: en modo demo nunca se instancia Firestore.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Flujo de proyectos ordenados del más reciente al más antiguo.
  Stream<List<ProjectModel>> watchProjects() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(DemoData.projects);
    }
    return withDemoFallback(
      _collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ProjectModel.fromDoc)
                .toList(growable: false),
          ),
      DemoData.projects,
    );
  }

  /// Alterna el estado "guardado" de un proyecto para el usuario [uid].
  ///
  /// Devuelve `true` si el cambio se escribió en Firestore.
  Future<bool> toggleSave(ProjectModel project, String uid) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    final saved = project.isSavedBy(uid) || project.saved;
    try {
      await _collection.doc(project.id).update({
        'savedBy': saved
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
        'saved': !saved,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Proyectos guardados por un usuario (para el perfil).
  Stream<List<ProjectModel>> watchSavedProjects(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <ProjectModel>[]);
    }
    return withFallback(
      _collection.where('savedBy', arrayContains: uid).snapshots().map((s) {
        final projects = s.docs.map(ProjectModel.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return projects;
      }),
      const <ProjectModel>[],
    );
  }

  /// Crea un proyecto nuevo.
  Future<bool> create({
    required String title,
    required String tech,
    required String imageUrl,
    required String authorName,
    required String authorAvatar,
    String? authorId,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.add({
        'title': title,
        'tech': tech,
        'imageUrl': imageUrl,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorId': authorId,
        'saved': false,
        'savedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
