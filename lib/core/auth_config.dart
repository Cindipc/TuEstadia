import 'package:flutter/foundation.dart';

/// Configuración del flujo de autenticación.
///
/// **Ahora mismo el registro es inmediato:** no se exige confirmar el correo y
/// la cuenta queda activa al crearse.
///
/// Para activar la verificación de correo más adelante, sin tocar la lógica:
///
/// ```bash
/// flutter run --dart-define=TUESTADIA_REQUIRE_EMAIL_VERIFICATION=true
/// ```
///
/// o cambia el valor por defecto de [requireEmailVerification].
class AuthConfig {
  AuthConfig._();

  static const bool _fromEnvironment = bool.fromEnvironment(
    'TUESTADIA_REQUIRE_EMAIL_VERIFICATION',
  );

  static bool? _override;

  /// `true` cuando se exige el correo verificado para entrar a la app.
  ///
  /// Con `false` (por defecto) el registro es instantáneo: no se envía ningún
  /// correo de confirmación y el usuario entra directo.
  static bool get requireEmailVerification =>
      _override ?? _fromEnvironment;

  /// Enlace al que vuelve el usuario después de confirmar el correo en web.
  ///
  /// `null` usa el dominio por defecto de Firebase Auth
  /// (`https://<proyecto>.firebaseapp.com/__/auth/action`).
  static const String? verificationContinueUrl = null;

  /// Espera mínima entre reenvíos del correo de verificación.
  static const Duration resendCooldown = Duration(seconds: 60);

  /// Permite forzar la configuración desde las pruebas.
  @visibleForTesting
  static set requireEmailVerification(bool value) => _override = value;

  /// Vuelve al valor por defecto (útil en pruebas).
  @visibleForTesting
  static void reset() => _override = null;
}
