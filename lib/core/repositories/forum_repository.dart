import 'package:cloud_firestore/cloud_firestore.dart';

import '../demo_data.dart';
import '../firebase_bootstrap.dart';
import '../models/forum_media.dart';
import '../models/forum_poll.dart';
import '../models/forum_post.dart';
import '../models/forum_profile.dart';
import '../models/forum_search_query.dart';
import '../services/forum_trend_engine.dart';
import '../stream_utils.dart';

/// Acceso a la colección `posts` de Firestore.
///
/// Las respuestas se guardan en la misma colección con `parentPostId`, igual
/// que en `fwitter_reborn`. Así una sola consulta (`orderBy createdAt`) trae el
/// foro completo y se particiona en memoria, sin índices compuestos.
class ForumRepository {
  ForumRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'posts';
  static const String profilesCollection = 'profiles';

  final FirebaseFirestore? _injected;

  /// Acceso perezoso: en modo demo nunca se instancia Firestore.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Flujo con todas las publicaciones (raíces y respuestas).
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

  /// Publicaciones raíz (sin padre), de más reciente a más antigua.
  static List<ForumPostModel> rootPosts(List<ForumPostModel> all) {
    final roots = all.where((post) => post.isRoot).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return roots;
  }

  /// Respuestas directas de [parentId], de más antigua a más reciente.
  static List<ForumPostModel> repliesOf(
    List<ForumPostModel> all,
    String parentId,
  ) {
    final replies = all
        .where((post) => post.parentPostId == parentId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return replies;
  }

  /// Mapa `id del post → número de respuestas` en una sola pasada.
  static Map<String, int> replyCountsOf(List<ForumPostModel> all) {
    final counts = <String, int>{};
    for (final post in all) {
      final parentId = post.parentPostId;
      if (parentId == null) continue;
      counts[parentId] = (counts[parentId] ?? 0) + 1;
    }
    return counts;
  }

  /// Publicaciones que cumplen [query], de más reciente a más antigua.
  static List<ForumPostModel> searchPosts(
    List<ForumPostModel> all,
    ForumSearchQuery query,
  ) {
    final results = all.where(query.matches).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  /// Ordena por relevancia (interacción ponderada por recencia).
  static List<ForumPostModel> sortByRelevance(
    List<ForumPostModel> posts, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    double scoreOf(ForumPostModel post) =>
        ForumTrendEngine.engagementOf(post) *
        ForumTrendEngine.recencyFactor(post.createdAt, reference);

    final sorted = [...posts]
      ..sort((a, b) {
        final byScore = scoreOf(b).compareTo(scoreOf(a));
        if (byScore != 0) return byScore;
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted;
  }

  /// Alterna el like del usuario [uid].
  ///
  /// Usa un array de uids (como la referencia) más un contador desnormalizado,
  /// así el like se puede quitar y sobrevive a recargas.
  Future<bool> toggleLike(ForumPostModel post, String uid) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    final liked = post.isLikedBy(uid);
    try {
      await _collection.doc(post.id).update({
        'likedBy': liked
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(liked ? -1 : 1),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Alterna el estado "guardado" del usuario [uid].
  Future<bool> toggleSave(ForumPostModel post, String uid) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    final saved = post.isSavedBy(uid);
    try {
      final batch = _firestore.batch();
      batch.update(_collection.doc(post.id), {
        'savedBy': saved
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
        'saved': !saved,
      });
      batch.set(
        _firestore.collection(profilesCollection).doc(uid),
        {
          'savedCount': FieldValue.increment(saved ? -1 : 1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Registra una vista del hilo (arrayUnion es idempotente por uid).
  Future<bool> addView(String postId, String uid) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.doc(postId).update({
        'views': FieldValue.arrayUnion([uid]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Crea una publicación nueva. Si [parentPostId] no es nulo, es una respuesta.
  ///
  /// Además del documento en `posts`, actualiza el contador del padre y el
  /// documento `profiles/{authorId}` para vincular la autoría.
  Future<bool> createPost({
    required String question,
    required String code,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    String? parentPostId,
    List<ForumMediaModel> media = const [],
    List<String> tags = const [],
    String? location,
    ForumPollModel? poll,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;

    try {
      final postRef = _collection.doc();
      final batch = _firestore.batch();

      batch.set(postRef, {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'question': question,
        'code': code,
        'media': media.map((item) => item.toMap()).toList(growable: false),
        'tags': tags,
        'location': location,
        'poll': poll?.toMap(),
        'likes': 0,
        'likedBy': <String>[],
        'replies': 0,
        'saved': false,
        'savedBy': <String>[],
        'views': <String>[],
        'parentPostId': parentPostId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (parentPostId != null) {
        batch.update(_collection.doc(parentPostId), {
          'replies': FieldValue.increment(1),
        });
      }

      final profile = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        parentPostId == null ? 'postsCount' : 'repliesCount':
            FieldValue.increment(1),
      };
      if (authorName.trim().isNotEmpty) {
        profile['displayName'] = authorName.trim();
      }
      if (authorAvatar.trim().isNotEmpty) {
        profile['photoUrl'] = authorAvatar.trim();
      }

      batch.set(
        _firestore.collection(profilesCollection).doc(authorId),
        profile,
        SetOptions(merge: true),
      );

      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina una publicación propia (las reglas también lo impiden si no eres
  /// el autor). Si tiene respuestas, también se eliminan.
  Future<bool> deletePost(String postId) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      final replies = await _collection
          .where('parentPostId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (final reply in replies.docs) {
        batch.delete(reply.reference);
      }
      batch.delete(_collection.doc(postId));
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Vota en la encuesta de un post y devuelve la encuesta actualizada.
  Future<ForumPollModel?> voteInPoll(
    String postId,
    String optionId,
    String uid,
  ) async {
    if (!FirebaseBootstrap.isAvailable) return null;
    try {
      final ref = _collection.doc(postId);
      return await _firestore.runTransaction<ForumPollModel?>((transaction) async {
        final snapshot = await transaction.get(ref);
        final rawPoll = snapshot.data()?['poll'];
        if (rawPoll is! Map) return null;

        final poll = ForumPollModel.fromMap(
          Map<String, dynamic>.from(rawPoll),
        );
        final updated = poll.vote(optionId, uid);
        transaction.update(ref, {'poll': updated.toMap()});
        return updated;
      });
    } catch (_) {
      return null;
    }
  }

  /// Perfil del usuario (para mostrar su actividad en el foro).
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream<Map<String, dynamic>?>.value(null);
    }
    return withFallback<Map<String, dynamic>?>(
      _firestore
          .collection(profilesCollection)
          .doc(uid)
          .snapshots()
          .map((doc) => doc.data()),
      null,
    );
  }

  /// Perfiles para la pestaña "Personas" de la búsqueda.
  Stream<List<ForumProfileModel>> watchProfiles({int limit = 50}) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <ForumProfileModel>[]);
    }
    return withFallback(
      _firestore
          .collection(profilesCollection)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(ForumProfileModel.fromDoc)
                .toList(growable: false),
          ),
      const <ForumProfileModel>[],
    );
  }
}
