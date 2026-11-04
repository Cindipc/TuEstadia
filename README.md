# TuEstadia

TuEstadia es una app para aprender programación en comunidad, con un feed de proyectos, una biblioteca y un espacio para resolver dudas.

## Pantallas

| Pantalla | Descripción |
|---|---|
| **Home - Feed** | Buscador + filtros, carrusel de chips por tecnología y grilla de 2 columnas con tarjetas de proyecto. |
<<<<<<< Updated upstream
| **Biblioteca** | Sección **Proyectos** con el contenido de una carpeta pública de Google Drive. |
| **Foro de Dudas** | Hilos de preguntas con línea de tiempo, bloque de código con resaltado de sintaxis y barra de acciones. |
=======
| **Biblioteca** | Carrusel de cursos y línea de tiempo de capítulos (nodos + línea vertical con `CustomPainter`). |
| **Foro de Dudas** | Estilo Twitter: hilos con respuestas, likes por usuario, imágenes/vídeos/GIF (Cloudinary), encuestas, búsqueda con pestañas, tendencias calculadas y borrado de publicaciones propias. |
>>>>>>> Stashed changes
| **Perfil** | Datos del usuario, estadísticas y cierre de sesión. |

Todas las pantallas usan el tema **Neo-Dark** (`#121826` / `#1E293B` / `#38BDF8` / `#34D399`).

## Estructura

```text
lib/
├── main.dart                     # Arranque + _AuthGate (login / shell)
├── app_theme.dart                # Paleta y temas (neoDark, dark, light)
├── firebase_options.dart         # Credenciales de Firebase
├── core/
│   ├── firebase_bootstrap.dart   # Inicialización segura + modo demo
│   ├── auth_service.dart         # Login, registro, reset, logout, verificación
│   ├── auth_config.dart          # Flag de verificación de correo
│   ├── auth_error_messages.dart  # Errores de Auth en español
│   ├── seed_service.dart         # Sembrado de datos en Firestore
│   ├── demo_data.dart            # Datos de prueba
│   ├── stream_utils.dart         # Fallback de streams (vacío/error)
│   ├── models/                   # Project, Course, Chapter, ForumPost
│   ├── repositories/             # Project, Library, Forum
│   └── widgets/                  # AppAvatar, NetworkCover
└── features/
    ├── auth/                     # Registro + verificación de correo
    ├── feed/home_page.dart
    ├── library/library_page.dart
    ├── forum/
    │   ├── forum_page.dart       # Recientes / Tendencias / Sin responder
    │   ├── screens/              # Composer, detalle, búsqueda, tendencias, filtros
    │   └── widgets/              # Tarjetas, media, encuesta, composer bar
    ├── profile/profile_page.dart
    └── shell/main_shell.dart
```

## Firebase

Proyecto conectado: **`fwitter-7596d`** (credenciales en
`lib/firebase_options.dart`).

La capa de datos usa **Cloud Firestore** con `StreamBuilder`, así que los
cambios se reflejan en pantalla sin recargar. **Firebase Auth** (email y
contraseña) alimenta la pantalla de login:

El foro guarda las respuestas en la misma colección `posts` con `parentPostId`
(y así se muestran en el hilo), y los likes como `likedBy` + contador `likes`
por usuario. La autoría se vincula con `profiles/{uid}`. Las imágenes, vídeos y
GIF se suben a **Cloudinary** (cloud `xnnb3pfg`, preset `fwitter_preset`).

| Acción | Implementación |
|---|---|
| Ingresar | `signInWithEmailAndPassword` |
| Registrarse | `RegisterPage` (nombre, correo, contraseña y confirmación) → `createUserWithEmailAndPassword` + documento en `profiles` |
| Recuperar contraseña | `sendPasswordResetEmail` |
| Cerrar sesión | `signOut` desde el perfil |

El registro es inmediato: **no se pide confirmar el correo**. El flujo de
verificación ya está implementado en `lib/features/auth/email_verification_page.dart`
y se activa con `AuthConfig.requireEmailVerification` o con
`--dart-define=TUESTADIA_REQUIRE_EMAIL_VERIFICATION=true`.

Si Firestore no responde (sin conexión, sin reglas o colecciones vacías), la app
sigue funcionando con los datos de `lib/core/demo_data.dart` y lo avisa en el
perfil. Para pasar a datos reales:

1. Publica [`firestore.rules`](firestore.rules) en **Firestore → Rules**.
2. Inicia sesión y entra a **Perfil → “Cargar datos de prueba en Firestore”**.

```bash
flutter pub get
flutter analyze
flutter test
flutter run             # web
flutter run -d windows
```

Detalles y esquema de colecciones: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) y
[`Plan.md`](Plan.md).

## Google Drive (Proyectos)

La sección **Proyectos** de la Biblioteca lista, en modo solo lectura, el
contenido de una carpeta pública de Google Drive mediante la API v3.

La API key y el ID de la carpeta se leen en tiempo de compilación, nunca desde
el código. Crea un `dart_defines.json` local (ya está en `.gitignore`) copiando
`dart_defines.example.json` y rellena:

```json
{
  "GOOGLE_DRIVE_API_KEY": "TU_API_KEY",
  "GOOGLE_DRIVE_FOLDER_ID": "TU_FOLDER_ID"
}
```

Después ejecuta la app con ese archivo:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

En VS Code también puedes usar la configuración **TuEstadia (con Google Drive)**
del panel *Run and Debug*. Como alternativa, pasa los valores directo:

```bash
flutter run --dart-define=GOOGLE_DRIVE_API_KEY=TU_API_KEY --dart-define=GOOGLE_DRIVE_FOLDER_ID=TU_FOLDER_ID
```

La carpeta debe ser accesible sin iniciar sesión: en Google Drive, clic derecho
sobre la carpeta → **Compartir** → **Acceso general** → **Cualquier persona con
el enlace** → **Lector**. Una API key por sí sola no da acceso a carpetas
privadas. Además, la API de Google Drive debe estar habilitada en el proyecto de
Google Cloud y la clave debe permitir la API de Drive.

## Comandos

```bash
flutter pub get        # dependencias
flutter analyze        # análisis estático
flutter test           # pruebas de widget
flutter run            # ejecutar
```
