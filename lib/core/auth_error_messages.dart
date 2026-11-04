import 'package:firebase_auth/firebase_auth.dart';

/// Traduce los errores de Firebase Auth a mensajes en español.
///
/// Se usa en el login, el registro y la verificación de correo para que el
/// usuario vea siempre un mensaje entendible.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'El correo electrónico no es válido.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Correo o contraseña incorrectos.';
    case 'email-already-in-use':
      return 'Ese correo ya tiene una cuenta. Inicia sesión o recupera tu '
          'contraseña.';
    case 'weak-password':
      return 'La contraseña es demasiado débil: usa al menos 6 caracteres.';
    case 'network-request-failed':
      return 'Sin conexión con Firebase. Revisa tu red.';
    case 'too-many-requests':
      return 'Demasiados intentos. Espera un momento y vuelve a intentarlo.';
    case 'operation-not-allowed':
      return 'El registro con correo y contraseña está deshabilitado en '
          'Firebase.';
    case 'user-disabled':
      return 'Esta cuenta está deshabilitada.';
    case 'requires-recent-login':
      return 'Por seguridad, vuelve a iniciar sesión para continuar.';
    case 'no-current-user':
      return 'No hay una sesión activa.';
    default:
      return e.message ?? 'Ocurrió un error inesperado.';
  }
}
