import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_config.dart';
import 'firebase_bootstrap.dart';

/// Autenticación con Firebase Auth (email y contraseña).
///
/// Centraliza las llamadas para que las pantallas no dependan directamente del
/// SDK y para crear el documento de perfil al registrarse.
class AuthService {
  AuthService._();

  static bool get isAvailable => FirebaseBootstrap.isAvailable;

  /// `true` si el registro debe confirmar el correo antes de entrar.
  static bool get requiresEmailVerification =>
      AuthConfig.requireEmailVerification;

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
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null && user.emailVerified) {
      await _touchProfile(user, {'emailVerified': true, 'status': 'active'});
    }
    return credential;
  }

  /// Crea la cuenta y su documento en `profiles`.
  ///
  /// Por defecto la cuenta queda activa al instante. Si
  /// [AuthConfig.requireEmailVerification] está activo, se envía el correo de
  /// verificación y el perfil queda en estado `pending`.
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

      if (AuthConfig.requireEmailVerification) {
        try {
          await _sendVerification(user);
        } catch (_) {
          // El usuario puede reenviarlo desde la pantalla de verificación.
        }
      }
    }
    return credential;
  }

  /// Reenvía el correo de verificación de la cuenta actual.
  static Future<void> sendVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay una sesión activa.',
      );
    }

    await _sendVerification(user);
    await _touchProfile(user, {
      'verificationSentAt': FieldValue.serverTimestamp(),
    });
  }

  /// Recarga el usuario y devuelve su estado actual.
  ///
  /// Si el correo ya está verificado, sincroniza el documento de perfil.
  static Future<User?> reloadAndCheckVerified() async {
    final user = currentUser;
    if (user == null) return null;

    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;

    if (refreshed != null && refreshed.emailVerified) {
      await _touchProfile(refreshed, {
        'emailVerified': true,
        'status': 'active',
      });
    }
    return refreshed;
  }

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    if (!isAvailable) return;
    await FirebaseAuth.instance.signOut();
  }

  static Future<void> _sendVerification(User user) async {
    final continueUrl = AuthConfig.verificationContinueUrl;
    await user.sendEmailVerification(
      continueUrl == null
          ? null
          : ActionCodeSettings(url: continueUrl, handleCodeInApp: false),
    );
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
            'emailVerified': user.emailVerified,
            'status': AuthConfig.requireEmailVerification
                ? 'pending'
                : 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Si las reglas de Firestore bloquean la escritura, el registro sigue
      // funcionando: el perfil se creará más adelante.
    }
  }

  /// Actualiza campos sueltos del perfil sin romper si falla.
  static Future<void> _touchProfile(
    User user,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Sin permisos o sin red: no es crítico para iniciar sesión.
    }
  }
}
