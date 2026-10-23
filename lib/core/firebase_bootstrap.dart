import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Arranque de Firebase.
///
/// La app nunca se cae por culpa de Firebase: si las credenciales no están
/// configuradas (o la plataforma no soporta Firebase, como Linux), la app
/// sigue funcionando en **modo demo** con los datos de `DemoData`.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static bool _available = false;
  static String? _error;

  /// `true` si Firebase quedó inicializado correctamente.
  static bool get isAvailable => _available;

  /// `true` si hay credenciales reales configuradas.
  static bool get hasCredentials => DefaultFirebaseOptions.isConfigured;

  /// Mensaje de error si la inicialización falló.
  static String? get error => _error;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!DefaultFirebaseOptions.isConfigured) {
      _error =
          'No hay credenciales de Firebase configuradas. '
          'Edita lib/firebase_options.dart o ejecuta `flutterfire configure`.';
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;
    } catch (e) {
      _available = false;
      _error = e.toString();
    }
  }
}
