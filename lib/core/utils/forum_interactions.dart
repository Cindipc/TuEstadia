import 'package:flutter/foundation.dart';

import '../models/forum_post.dart';
import '../auth_service.dart';
import '../firebase_bootstrap.dart';

/// Utilidades compartidas para el estado optimista del foro.
///
/// El like se pinta al instante en la UI y, cuando Firestore devuelve el
/// documento confirmado, se descarta el valor local.

/// `true` si dos versiones de un post tienen el mismo estado de interacción.
bool sameInteraction(ForumPostModel a, ForumPostModel b) {
  return a.likes == b.likes &&
      a.saved == b.saved &&
      setEquals(a.likedBy.toSet(), b.likedBy.toSet()) &&
      setEquals(a.savedBy.toSet(), b.savedBy.toSet());
}

/// Aplica los cambios optimistas pendientes sobre la lista del servidor.
List<ForumPostModel> applyPending(
  List<ForumPostModel> posts,
  Map<String, ForumPostModel> pending,
) {
  if (pending.isEmpty) return posts;
  return posts
      .map((post) => pending[post.id] ?? post)
      .toList(growable: false);
}

/// Elimina los pendientes que ya llegaron confirmados desde Firestore.
void pruneConfirmed(
  Map<String, ForumPostModel> pending,
  List<ForumPostModel> incoming,
) {
  if (pending.isEmpty) return;
  pending.removeWhere((id, optimistic) {
    final index = incoming.indexWhere((post) => post.id == id);
    if (index == -1) return true;
    return sameInteraction(incoming[index], optimistic);
  });
}

/// uid con el que se registran las interacciones.
///
/// Si no hay sesión pero la app corre en modo demo, devuelve un uid local para
/// que los likes funcionen en la demo. Con Firebase disponible exige sesión.
String? forumInteractionUid() {
  final uid = AuthService.currentUser?.uid;
  if (uid != null) return uid;
  return FirebaseBootstrap.isAvailable ? null : 'demo-user';
}
