import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  ///
  /// Si Firestore no está disponible o falla, devuelve una lista vacía para
  /// que la UI muestre su estado vacío en lugar de publicaciones de ejemplo.
  /// También escucha los bloqueos del usuario para ocultar a esos autores en
  /// todas las pantallas del foro.
  Stream<List<ForumPostModel>> watchPosts() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <ForumPostModel>[]);
    }

    late StreamController<List<ForumPostModel>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? postsSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? blocksSubscription;
    var posts = const <ForumPostModel>[];
    var blocked = const <String>{};

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        posts
            .where((post) => !blocked.contains(post.authorId))
            .toList(growable: false),
      );
    }

    Future<void> start() async {
      postsSubscription = _collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            posts = snapshot.docs
                .map(ForumPostModel.fromDoc)
                .toList(growable: false);
            emit();
          }, onError: (_) => emit());

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        blocksSubscription = _firestore
            .collection('blocks')
            .where('ownerId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
              blocked = snapshot.docs
                  .map((doc) => doc.data()['blockedId'])
                  .whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .toSet();
              emit();
            }, onError: (_) {});
      }
    }

    controller = StreamController<List<ForumPostModel>>(
      onListen: start,
      onCancel: () async {
        await postsSubscription?.cancel();
        await blocksSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Guarda un reporte para que el equipo moderador lo revise.
  Future<bool> reportPost({
    required String postId,
    required String reporterId,
    required String reason,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reporterId': reporterId,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Oculta las publicaciones de [blockedId] para [ownerId].
  Future<bool> blockUser({
    required String ownerId,
    required String blockedId,
  }) async {
    if (!FirebaseBootstrap.isAvailable || ownerId == blockedId) return false;
    try {
      await _firestore.collection('blocks').doc('${ownerId}_$blockedId').set({
        'ownerId': ownerId,
        'blockedId': blockedId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Publicaciones creadas por el usuario.
  Stream<List<ForumPostModel>> watchMyPosts(String uid) {
    return _watchByField('authorId', uid, array: false);
  }

  /// Publicaciones a las que el usuario dio "me gusta".
  Stream<List<ForumPostModel>> watchLikedPosts(String uid) {
    return _watchByField('likedBy', uid, array: true);
  }

  /// Publicaciones guardadas por el usuario.
  Stream<List<ForumPostModel>> watchSavedPosts(String uid) {
    return _watchByField('savedBy', uid, array: true);
  }

  Stream<List<ForumPostModel>> _watchByField(
    String field,
    String uid, {
    required bool array,
  }) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <ForumPostModel>[]);
    }

    final query = array
        ? _collection.where(field, arrayContains: uid)
        : _collection.where(field, isEqualTo: uid);

    return withFallback(
      query.snapshots().map((snapshot) {
        final posts = snapshot.docs.map(ForumPostModel.fromDoc).toList();
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      }),
      const <ForumPostModel>[],
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
    final replies = all.where((post) => post.parentPostId == parentId).toList()
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
      batch.set(_firestore.collection(profilesCollection).doc(uid), {
        'savedCount': FieldValue.increment(saved ? -1 : 1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
      return await _firestore.runTransaction<ForumPollModel?>((
        transaction,
      ) async {
        final snapshot = await transaction.get(ref);
        final rawPoll = snapshot.data()?['poll'];
        if (rawPoll is! Map) return null;

        final poll = ForumPollModel.fromMap(Map<String, dynamic>.from(rawPoll));
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
