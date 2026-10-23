# TuEstadia

TuEstadia es una app para aprender programación en comunidad, con un feed de proyectos, una biblioteca y un espacio para resolver dudas.

## Pantallas

| Pantalla | Descripción |
|---|---|
| **Home - Feed** | Buscador + filtros, carrusel de chips por tecnología y grilla de 2 columnas con tarjetas de proyecto. |
| **Biblioteca** | Carrusel de cursos y línea de tiempo de capítulos (nodos + línea vertical con `CustomPainter`). |
| **Foro de Dudas** | Hilos de preguntas con línea de tiempo, bloque de código con resaltado de sintaxis y barra de acciones. |
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
│   ├── demo_data.dart            # Datos de prueba
│   ├── stream_utils.dart         # Fallback de streams
│   ├── models/                   # Project, Course, Chapter, ForumPost
│   ├── repositories/             # Project, Library, Forum
│   └── widgets/                  # AppAvatar, NetworkCover
└── features/
    ├── feed/home_page.dart
    ├── library/library_page.dart
    ├── forum/forum_page.dart
    ├── profile/profile_page.dart
    └── shell/main_shell.dart
```

## Firebase

La capa de datos usa **Cloud Firestore** con `StreamBuilder`, así que los
cambios se reflejan en pantalla sin recargar. **Firebase Auth** (email y
contraseña) alimenta la pantalla de login.

Si las credenciales no están configuradas, la app arranca en **modo demo** con
los datos de `lib/core/demo_data.dart`.

```bash
flutterfire configure          # genera lib/firebase_options.dart
flutter pub get
flutter run
```

Detalles y esquema de colecciones: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) y
[`Plan.md`](Plan.md).

## Comandos

```bash
flutter pub get        # dependencias
flutter analyze        # análisis estático
flutter test           # pruebas de widget
flutter run            # ejecutar
```
