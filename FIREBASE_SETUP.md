# Configuración de Firebase — TuEstadia

Toda la capa de datos está implementada en `lib/core/`. Este documento explica
cómo conectar el proyecto con tu proyecto de Firebase.

---

## 1. Crear el proyecto en Firebase

1. Entra en <https://console.firebase.google.com> y crea un proyecto (o usa el
   que ya tienes).
2. Ve a **Build → Firestore Database** y crea la base de datos en modo
   *production*.
3. Ve a **Build → Authentication → Sign-in method** y activa **Email/Password**.
4. Registra las apps que vas a compilar:
   - Android: package `com.example.tuestadia`
   - iOS / macOS: bundle id `com.example.tuestadia`
   - Web: id de app web

---

## 2. Pegar las credenciales

### Opción A — `flutterfire configure` (recomendada)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Elige tu proyecto y las plataformas. El comando **sobrescribe**
`lib/firebase_options.dart` con los valores reales.

### Opción B — Manual

Abre `lib/firebase_options.dart` y reemplaza los valores `PLACEHOLDER_*` por
los que aparecen en la consola de Firebase:

```dart
static const String _apiKey    = 'AIza...';
static const String _appId     = '1:123456789:web:abc123';
static const String _projectId = 'mi-proyecto';
// ...
```

### Opción C — Variables de entorno / CI

```bash
flutter run --dart-define=FIREBASE_API_KEY=AIza... \
            --dart-define=FIREBASE_APP_ID=1:123456789:web:abc123 \
            --dart-define=FIREBASE_PROJECT_ID=mi-proyecto \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 \
            --dart-define=FIREBASE_WEB_APP_ID=1:123456789:web:abc123
```

---

## 3. Colecciones y documentos esperados

| Colección | Campos |
|---|---|
| `projects` | `title`, `tech`, `imageUrl`, `authorName`, `authorAvatar`, `saved`, `createdAt` |
| `courses` | `title`, `subtitle`, `iconKey`, `colorValue`, `gradientStart`, `gradientEnd` |
| `chapters` | `courseId`, `title`, `chapterNumber`, `progress` |
| `posts` | `authorName`, `authorAvatar`, `question`, `code`, `likes`, `replies`, `saved`, `createdAt` |
| `profiles` | `displayName`, `email`, `photoUrl`, `bio` |

Los repositorios (`lib/core/repositories/`) leen esas colecciones con
`StreamBuilder`, así que cualquier cambio en Firestore se refleja en pantalla
sin recargar.

### Script de ejemplo (Node.js) para poblar la base

```js
// scripts/seed.js  ->  node scripts/seed.js
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ credential: admin.credential.cert(require('./serviceAccount.json')) });
const db = getFirestore();

async function seed() {
  await db.collection('projects').add({
    title: 'UI Clone in Flutter',
    tech: 'Flutter',
    imageUrl: 'https://picsum.photos/seed/1/480/320',
    authorName: 'Carla Méndez',
    authorAvatar: 'https://i.pravatar.cc/120?img=12',
    saved: false,
    createdAt: new Date(),
  });
}
seed();
```

---

## 4. Modo demo (sin Firebase)

Si las credenciales no están configuradas, la app **no se rompe**: entra en
*modo demo* y muestra los datos de `lib/core/demo_data.dart`. En el login
aparece el enlace **“Explorar en modo demo”**.

Esto también cubre la plataforma **Linux**, donde Firebase no está soportado.

---

## 5. Notas por plataforma

- **Android / iOS / Web**: no necesitas `google-services.json` ni
  `GoogleService-Info.plist` mientras pases las opciones desde Dart
  (`Firebase.initializeApp(options: ...)`). Si prefieres usar esos archivos,
  añade el plugin de Google Services y el de Firebase iOS.
- **Windows / macOS**: requieren `FlutterFire CLI` instalado y los plugins
  nativos ya habilitados por Flutter.
- **Linux**: `firebase_core` no tiene soporte; la app corre en modo demo.

---

## 6. Structure del código

```text
lib/
├── firebase_options.dart          # Credenciales (generado por FlutterFire CLI)
├── core/
│   ├── firebase_bootstrap.dart    # Inicialización segura + modo demo
│   ├── demo_data.dart             # Datos de prueba
│   ├── stream_utils.dart          # Fallback de streams
│   ├── models/                    # Project, Course, Chapter, ForumPost
│   ├── repositories/              # Project, Library, Forum
│   └── widgets/                   # AppAvatar, NetworkCover
└── features/
    ├── feed/home_page.dart        # Home - Feed (Plan.md)
    ├── library/library_page.dart  # Biblioteca (Plan.md)
    ├── forum/forum_page.dart      # Foro de Dudas (Plan.md)
    ├── profile/profile_page.dart
    └── shell/main_shell.dart      # Navegación inferior
```
