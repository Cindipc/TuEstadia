import 'package:cloud_firestore/cloud_firestore.dart';

import '../demo_data.dart';
import '../firebase_bootstrap.dart';
import '../models/forum_post.dart';
import '../stream_utils.dart';

/// Acceso a la colección `posts` de Firestore.
class ForumRepository {
  ForumRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'posts';

  final FirebaseFirestore? _injected;

  /// Acceso perezoso: en modo demo nunca se instancia Firestore.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Flujo de publicaciones del foro, de más reciente a más antigua.
  Stream<List<ForumPostModel>> watchPosts() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(DemoData.posts);
    }
    return withDemoFallback(
      _collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ForumPostModel.fromDoc)
                .toList(growable: false),
          ),
      DemoData.posts,
    );
  }

  /// Alterna el "like" de una publicación.
  Future<bool> toggleLike(ForumPostModel post) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.doc(post.id).update({'likes': post.likes + 1});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Alterna el estado "guardado" de una publicación.
  Future<bool> toggleSave(ForumPostModel post) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.doc(post.id).update({'saved': !post.saved});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Crea una publicación nueva en el foro.
  Future<bool> createPost({
    required String question,
    required String code,
    required String authorName,
    required String authorAvatar,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.add({
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'question': question,
        'code': code,
        'likes': 0,
        'replies': 0,
        'saved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
