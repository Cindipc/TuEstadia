import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'local_env.dart';

/// Credenciales OAuth usadas por el inicio de sesión con Google.
///
/// Orden de prioridad para cada valor:
///   1. `--dart-define` (CI / builds explícitos).
///   2. Asset `.env` (flutter_dotenv).
///   3. Archivo `.env` local en desktop/móvil (respaldo de desarrollo).
///   4. Valor por defecto del proyecto `fwitter-7596d`.
///
/// El *server client ID* es el cliente OAuth **Web** del proyecto de Firebase.
/// Se usa en Android para que Google Sign-In devuelva un `idToken` válido. En
/// iOS/macOS además se necesita el cliente OAuth de la app iOS.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String _serverClientIdDefine = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const String _iosClientIdDefine = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Cliente OAuth Web del proyecto `fwitter-7596d`.
  ///
  /// Es un identificador público (no es un secreto). Se puede sobreescribir con
  /// `GOOGLE_SERVER_CLIENT_ID` si se cambia de proyecto de Firebase.
  static const String defaultServerClientId =
      '855255390470-qit6vifl2o2o34235gfa9i1n1sn84lq8.apps.googleusercontent.com';

  /// Cliente OAuth iOS del proyecto `fwitter-7596d`.
  static const String defaultIosClientId =
      '855255390470-t7he8rgoa7krv8e82ojpg0sg7sf1galg.apps.googleusercontent.com';

  static String get serverClientId => _resolve(
    'GOOGLE_SERVER_CLIENT_ID',
    _serverClientIdDefine,
    defaultServerClientId,
  );

  static String? get iosClientId {
    final value = _resolve(
      'GOOGLE_IOS_CLIENT_ID',
      _iosClientIdDefine,
      defaultIosClientId,
    );
    return value.isEmpty ? null : value;
  }

  static bool get isConfigured => serverClientId.trim().isNotEmpty;

  static String _resolve(String key, String define, String fallback) {
    final fromDefine = define.trim();
    if (fromDefine.isNotEmpty) return fromDefine;

    try {
      final fromAsset = dotenv.env[key]?.trim();
      if (fromAsset != null && fromAsset.isNotEmpty) return fromAsset;
    } catch (_) {
      // dotenv no inicializado (pruebas) o limpiado: se usa el respaldo.
    }

    final fromFile = (readLocalEnvValue(key) ?? '').trim();
    if (fromFile.isNotEmpty) return fromFile;

    return fallback;
  }
}
