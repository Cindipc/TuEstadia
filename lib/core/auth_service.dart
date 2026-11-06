import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_config.dart';
import 'config/google_auth_config.dart';
import 'firebase_bootstrap.dart';

/// Autenticación con Firebase Auth (email y contraseña).
///
/// Centraliza las llamadas para que las pantallas no dependan directamente del
/// SDK y para crear el documento de perfil al registrarse.
class AuthService {
  AuthService._();

  /// Inicialización única de Google Sign-In (la API 7.x exige llamarla una vez).
  static Future<void>? _googleInitialization;

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
    return _nameFor(user);
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

  /// Inicia sesión con Google y crea/actualiza su documento en `profiles`.
  ///
  /// En Android e iOS usa el selector nativo de cuentas de Google; en web usa
  /// el popup de Firebase Auth. El `idToken` de Google se intercambia por una
  /// sesión de Firebase, así que el resto de la app sigue usando
  /// [authStateChanges] sin cambios.
  static Future<UserCredential> signInWithGoogle() async {
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'firebase-unavailable',
        message: 'Firebase no está configurado.',
      );
    }

    final UserCredential credential;
    if (kIsWeb) {
      credential = await FirebaseAuth.instance.signInWithPopup(
        GoogleAuthProvider(),
      );
    } else {
      _ensureGooglePlatform();
      await _ensureGoogleInitialized();

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description:
              'Google no devolvió un idToken. Revisa el client ID web y el '
              'SHA-1 registrado en Firebase.',
        );
      }

      credential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }

    final user = credential.user;
    if (user != null) {
      await _ensureGoogleProfile(user, _nameFor(user));
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

    // Cierra también la sesión de Google para que el selector de cuentas no
    // reutilice al usuario anterior. Si Google nunca se inicializó, se ignora.
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // No es crítico para cerrar la sesión de Firebase.
      }
    }

    await FirebaseAuth.instance.signOut();
  }

  /// Elimina la cuenta del usuario y sus datos de Firestore.
  ///
  /// Si el usuario entró con correo/contraseña, [password] es obligatorio para
  /// reautenticarlo (Firebase exige un inicio de sesión reciente antes de
  /// borrar la cuenta). Si entró con Google, se abre el selector de cuentas.
  static Future<void> deleteAccount({String? password}) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay una sesión activa.',
      );
    }

    await _reauthenticateForDeletion(user, password: password);
    await _deleteUserData(user.uid);
    await user.delete();
  }

  static Future<void> _reauthenticateForDeletion(
    User user, {
    String? password,
  }) async {
    final providers = user.providerData
        .map((provider) => provider.providerId)
        .toSet();

    if (providers.contains('password')) {
      final email = user.email;
      if (email == null || password == null || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Escribe tu contraseña para confirmar la eliminación.',
        );
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return;
    }

    if (providers.contains('google.com')) {
      _ensureGooglePlatform();
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description:
              'Google no devolvió un idToken para confirmar la eliminación.',
        );
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }
  }

  static Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    Future<void> deleteWhere(
      String collection,
      String field,
      String value,
    ) async {
      final snapshot = await firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .get();
      for (var index = 0; index < snapshot.docs.length; index += 400) {
        final batch = firestore.batch();
        for (final doc in snapshot.docs.skip(index).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    Future<void> removeFromArray({
      required String collection,
      required String field,
      Map<String, dynamic>? extra,
    }) async {
      final snapshot = await firestore
          .collection(collection)
          .where(field, arrayContains: uid)
          .get();
      for (var index = 0; index < snapshot.docs.length; index += 400) {
        final batch = firestore.batch();
        for (final doc in snapshot.docs.skip(index).take(400)) {
          batch.update(doc.reference, {
            field: FieldValue.arrayRemove([uid]),
            ...?extra,
          });
        }
        await batch.commit();
      }
    }

    await deleteWhere('posts', 'authorId', uid);
    await deleteWhere('pins', 'authorId', uid);
    await deleteWhere('projects', 'authorId', uid);
    await deleteWhere('libraryItems', 'ownerId', uid);
    await deleteWhere('blocks', 'ownerId', uid);
    await deleteWhere('reports', 'reporterId', uid);

    // Quita las interacciones que dejan el uid expuesto en contenido ajeno.
    await removeFromArray(
      collection: 'posts',
      field: 'likedBy',
      extra: {'likes': FieldValue.increment(-1)},
    );
    await removeFromArray(
      collection: 'posts',
      field: 'savedBy',
      extra: {'saved': false},
    );
    await removeFromArray(collection: 'pins', field: 'savedBy', extra: null);
    await removeFromArray(
      collection: 'projects',
      field: 'savedBy',
      extra: null,
    );

    try {
      await firestore.collection('profiles').doc(uid).delete();
    } catch (_) {
      // Si no existía el perfil, la cuenta se elimina igualmente.
    }
  }

  static void _ensureGooglePlatform() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return;
    }
    throw const GoogleSignInException(
      code: GoogleSignInExceptionCode.providerConfigurationError,
      description:
          'El inicio de sesión con Google no está disponible en esta '
          'plataforma.',
    );
  }

  static Future<void> _ensureGoogleInitialized() async {
    final existing = _googleInitialization;
    if (existing != null) {
      await existing;
      return;
    }

    final isApple =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final initialization = GoogleSignIn.instance.initialize(
      clientId: isApple ? GoogleAuthConfig.iosClientId : null,
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    _googleInitialization = initialization;

    try {
      await initialization;
    } catch (_) {
      // Si la configuración falla, permite reintentar en el siguiente toque.
      _googleInitialization = null;
      rethrow;
    }
  }

  static String _nameFor(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Tu Estadia';
  }

  static Future<void> _sendVerification(User user) async {
    final continueUrl = AuthConfig.verificationContinueUrl;
    await user.sendEmailVerification(
      continueUrl == null
          ? null
          : ActionCodeSettings(url: continueUrl, handleCodeInApp: false),
    );
  }

  /// Crea el perfil si es la primera vez o actualiza solo los datos de Google.
  ///
  /// No usa [_saveProfile] para usuarios existentes porque eso sobrescribiría
  /// `createdAt` (y antes también la biografía) en cada inicio de sesión.
  static Future<void> _ensureGoogleProfile(
    User user,
    String displayName,
  ) async {
    try {
      final reference = FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid);
      final snapshot = await reference.get();

      if (!snapshot.exists) {
        await _saveProfile(user, displayName);
        return;
      }

      await reference.set({
        'displayName': displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'emailVerified': true,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Si Firestore falla, el inicio de sesión con Google sigue funcionando.
    }
  }

  static Future<void> _saveProfile(User user, String displayName) async {
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set(
        {
          'displayName': displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'emailVerified': user.emailVerified,
          'status': !AuthConfig.requireEmailVerification || user.emailVerified
              ? 'active'
              : 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
      await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Sin permisos o sin red: no es crítico para iniciar sesión.
    }
  }
}
