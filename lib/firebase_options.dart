// Configuración de Firebase para TuEstadia.
//
// ---------------------------------------------------------------------------
// CÓMO PEGAR TUS CREDENCIALES
// ---------------------------------------------------------------------------
// Opción A (recomendada, sin tocar código):
//   flutterfire configure
//   -> genera este archivo con tus valores reales.
//
// Opción B (archivo manual):
//   1. Firebase Console > Project settings > General > Your apps > SDK setup
//   2. Copia el bloque `firebase_options` que te da la consola.
//   3. Reemplaza los valores `PLACEHOLDER_*` de este archivo.
//
// Opción C (inyección por variables de entorno / CI):
//   flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=...
//   (los dart-define tienen prioridad sobre los valores por defecto)
//
// ---------------------------------------------------------------------------
// COLECCIONES ESPERADAS EN FIRESTORE
// ---------------------------------------------------------------------------
//   projects/  { title, tech, imageUrl, authorName, authorAvatar, saved, createdAt }
//   courses/   { title, subtitle, iconKey, colorValue, gradientStart, gradientEnd }
//   chapters/  { courseId, title, chapterNumber, progress }
//   posts/     { authorName, authorAvatar, question, code, likes, replies,
//                saved, createdAt }
//   profiles/  { displayName, email, photoUrl, bio }
// ---------------------------------------------------------------------------

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const String _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'PLACEHOLDER_API_KEY',
  );
  static const String _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: 'PLACEHOLDER_APP_ID',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: 'PLACEHOLDER_MESSAGING_SENDER_ID',
  );
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'PLACEHOLDER_PROJECT_ID',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'PLACEHOLDER_PROJECT_ID.firebaseapp.com',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'PLACEHOLDER_PROJECT_ID.appspot.com',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.example.tuestadia',
  );
  static const String _macosBundleId = String.fromEnvironment(
    'FIREBASE_MACOS_BUNDLE_ID',
    defaultValue: 'com.example.tuestadia',
  );
  static const String _webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: 'PLACEHOLDER_WEB_APP_ID',
  );

  /// `true` cuando ya se pegaron credenciales reales en este archivo
  /// (o se protégieron con `--dart-define`).
  static bool get isConfigured {
    if (_apiKey.startsWith('PLACEHOLDER') || _apiKey.isEmpty) return false;
    if (_projectId.startsWith('PLACEHOLDER') || _projectId.isEmpty) {
      return false;
    }
    if (_appId.startsWith('PLACEHOLDER') || _appId.isEmpty) return false;
    return true;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase no está soportado en Linux. La app corre en modo demo.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _apiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _iosBundleId,
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: _macosBundleId,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: _authDomain,
    storageBucket: _storageBucket,
  );
}
