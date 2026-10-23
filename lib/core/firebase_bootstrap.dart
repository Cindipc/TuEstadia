import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Arranque de Firebase.
///
/// La app nunca se cae por culpa de Firebase: si las credenciales no están
/// configuradas, la inicialización falla o la plataforma no está soportada
/// (Linux), la app sigue funcionando en **modo demo** con `DemoData`.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static bool _available = false;
  static String? _error;

  /// `true` si Firebase quedó inicializado correctamente.
  static bool get isAvailable => _available;

  /// Mensaje de error si la inicialización falló.
  static String? get error => _error;

  /// Proyecto de Firebase configurado (por ejemplo `fwitter-7596d`).
  static String? get projectId {
    if (!_available) return null;
    try {
      return Firebase.app().options.projectId;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;
      _error = null;
    } catch (e) {
      _available = false;
      _error = e.toString();
    }
  }
}
