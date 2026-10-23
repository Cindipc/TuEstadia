import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';

/// Autenticación con Firebase Auth (email y contraseña).
///
/// Centraliza las llamadas para que las pantallas no dependan directamente del
/// SDK y para crear el documento de perfil al registrarse.
class AuthService {
  AuthService._();

  static bool get isAvailable => FirebaseBootstrap.isAvailable;

  static User? get currentUser {
    if (!isAvailable) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Nombre visible del usuario (o `Tu Estadia` si no hay sesión).
  static String get displayName {
    final user = currentUser;
    if (user == null) return 'Tu Estadia';
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Tu Estadia';
  }

  static String? get photoUrl => currentUser?.photoURL;

  static String? get email => currentUser?.email;

  static Stream<User?> authStateChanges() {
    if (!isAvailable) return const Stream<User?>.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final user = credential.user;
    if (user != null) {
      final name = (displayName ?? '').trim().isEmpty
          ? email.trim().split('@').first
          : displayName!.trim();
      try {
        await user.updateDisplayName(name);
      } catch (_) {
        // Algunos backends no permiten actualizar el perfil de inmediato.
      }
      await _saveProfile(user, name);
    }
    return credential;
  }

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    if (!isAvailable) return;
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> _saveProfile(User user, String displayName) async {
    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set({
            'displayName': displayName,
            'email': user.email,
            'photoUrl': user.photoURL,
            'bio': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Si las reglas de Firestore bloquean la escritura, el registro sigue
      // funcionando: el perfil se creará más adelante.
    }
  }
}
