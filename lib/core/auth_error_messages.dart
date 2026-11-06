import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

/// Traduce los errores del SDK de Google Sign-In a mensajes en español.
String googleSignInErrorMessage(GoogleSignInException e) {
  switch (e.code) {
    case GoogleSignInExceptionCode.canceled:
      return 'Inicio de sesión con Google cancelado.';
    case GoogleSignInExceptionCode.clientConfigurationError:
      return 'Google Sign-In no está bien configurado. Revisa que el paquete '
          'Android y el SHA-1 coincidan con la app registrada en Firebase.';
    case GoogleSignInExceptionCode.providerConfigurationError:
      return 'El inicio de sesión con Google no está disponible en esta '
          'plataforma.';
    case GoogleSignInExceptionCode.uiUnavailable:
      return 'No se pudo abrir el selector de cuentas de Google. Inténtalo de '
          'nuevo.';
    case GoogleSignInExceptionCode.interrupted:
      return 'El inicio de sesión con Google se interrumpió. Inténtalo de '
          'nuevo.';
    case GoogleSignInExceptionCode.userMismatch:
      return 'La cuenta de Google no coincide con la sesión actual.';
    default:
      return e.description ?? 'No se pudo iniciar sesión con Google.';
  }
}
