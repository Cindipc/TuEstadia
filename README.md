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
│   ├── auth_service.dart         # Login, registro, reset, logout
│   ├── seed_service.dart         # Sembrado de datos en Firestore
│   ├── demo_data.dart            # Datos de prueba
│   ├── stream_utils.dart         # Fallback de streams (vacío/error)
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

Proyecto conectado: **`fwitter-7596d`** (credenciales en
`lib/firebase_options.dart`).

La capa de datos usa **Cloud Firestore** con `StreamBuilder`, así que los
cambios se reflejan en pantalla sin recargar. **Firebase Auth** (email y
contraseña) alimenta la pantalla de login:

| Acción | Implementación |
|---|---|
| Ingresar | `signInWithEmailAndPassword` |
| Registrarse | `createUserWithEmailAndPassword` + documento en `profiles` |
| Recuperar contraseña | `sendPasswordResetEmail` |
| Cerrar sesión | `signOut` desde el perfil |

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

## Comandos

```bash
flutter pub get        # dependencias
flutter analyze        # análisis estático
flutter test           # pruebas de widget
flutter run            # ejecutar
```
