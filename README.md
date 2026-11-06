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
| **Perfil** | Cabecera estilo Twitter con portada personalizable, avatar, bio y estadísticas; pestañas **Publicaciones / Me gusta / Guardados / Biblioteca**; menú `⋮` con editar perfil y cerrar sesión; edición con foto y portada (Cloudinary). |

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
    ├── profile/
    │   ├── profile_page.dart     # Perfil con 4 pestañas de actividad
    │   ├── edit_profile_page.dart# Editar nombre, @usuario, bio y foto
    │   └── widgets/              # Cabecera, selector y tile de biblioteca
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

La API key y el ID de la carpeta se leen de un archivo **`.env`** en la raíz del
proyecto (ya está en `.gitignore`). No hace falta pasar flags al ejecutar:

```bash
cp .env.example .env      # una vez
# edita .env y rellena:
# GOOGLE_DRIVE_API_KEY=TU_API_KEY
# GOOGLE_DRIVE_FOLDER_ID=TU_FOLDER_ID

flutter run               # sin --dart-define
```

Orden de prioridad de la configuración:

1. `--dart-define=GOOGLE_DRIVE_API_KEY=...` (CI o builds explícitos).
2. Asset `.env` empaquetado con la app.
3. Archivo `.env` local en desktop/móvil (respaldo de desarrollo).

También siguen funcionando `flutter run --dart-define-from-file=dart_defines.json`
y la configuración **TuEstadia (con Google Drive)** de VS Code.

> El `.env` se empaqueta dentro de la app y la key es visible para quien
> inspeccione el binario: restríngela en Google Cloud (solo Google Drive API y
> los orígenes/apps que uses).

La carpeta debe ser accesible sin iniciar sesión: en Google Drive, clic derecho
sobre la carpeta → **Compartir** → **Acceso general** → **Cualquier persona con
el enlace** → **Lector**. Una API key por sí sola no da acceso a carpetas
privadas. Además, la API de Google Drive debe estar habilitada en el proyecto de
Google Cloud y la clave debe permitir la API de Drive.

Cada archivo de la Biblioteca tiene un marcador para **añadirlo a tu perfil**
(colección `libraryItems`), de modo que aparece en la pestaña **Biblioteca** del
perfil.

## Comandos

```bash
flutter pub get        # dependencias
flutter analyze        # análisis estático
flutter test           # pruebas de widget
flutter run            # ejecutar
```
