Actúa como un desarrollador experto en Flutter. Necesito que programes la pantalla "Home - Feed" para mi app CodeShare basada en un diseño Neo-Dark.

Especificaciones visuales:

- Fondo principal: Color oscuro `#121826`. Fondo de tarjetas: `#1E293B`.
- Acento primario: Cyan `#38BDF8`. Acento secundario (éxito): Esmeralda `#34D399`.

Estructura de la pantalla:

1. Top Bar: Barra de búsqueda con bordes redondeados y texto "Search", junto a un ícono de filtro.
2. Categorías: Un carrusel horizontal de 'Chips'. El chip activo dice "Home - Feed" con fondo Cyan y texto negro. Los inactivos tienen fondo transparente y borde blanco.
3. Feed Principal: Un `GridView` de 2 columnas con tarjetas de proyectos.
4. Diseño de Tarjeta:
   - Imagen superior con bordes redondeados (usa un placeholder genérico de red).
   - Título en negrita (ej. "UI Clone in Flutter").
   - Etiqueta de tecnología debajo del título (ej. "Flutter").
   - Fila inferior con un Avatar circular (imagen de perfil), la palabra "Save" y un ícono de un marcador (bookmark) en color esmeralda simulando un botón.

Por favor, genera el código completo de esta vista en un archivo (ej. `home_page.dart`) usando datos estáticos simulados.

Actúa como un desarrollador experto en Flutter. Ahora programaremos la vista de "Biblioteca" con un diseño oscuro (`#121826`).

Estructura de la pantalla:

1. AppBar: Ícono de retroceso, título central "Biblioteca" y un ícono de libro a la derecha.
2. Carrusel Superior: Lista horizontal de tarjetas (libros/cursos). Cada tarjeta tiene un color sólido o gradiente, el título del curso (ej. "Python desde Cero"), un ícono representativo y un borde inferior redondeado.
3. Sección "Chapters": Una lista vertical que parece una línea de tiempo.
4. Diseño de la Lista Vertical (Línea de tiempo):
   - A la izquierda de cada ítem, hay un nodo circular conectado por una línea vertical al siguiente nodo.
   - A la derecha del nodo, la información: Título del curso, debajo "Chapter: X", una barra de progreso lineal (verde esmeralda `#34D399`), y un botón redondeado color Cyan (`#38BDF8`) que dice "Continuar leyendo".

Genera el código completo (ej. `library_page.dart`) e incluye un CustomPainter o un widget configurado inteligentemente para dibujar la línea vertical que conecta los nodos de los capítulos. Usa datos de prueba.

Actúa como un desarrollador experto en Flutter. Vamos a crear la pantalla "Foro de Dudas" usando nuestro tema oscuro (`#121826`).

Estructura de la pantalla:

1. AppBar: Avatar del usuario a la izquierda, título "Foro de Dudas" centrado, y un Floating Action Button (FAB) pequeño color Cyan con ícono de lápiz a la derecha para "crear post".
2. Feed de Hilos: Un `ListView` que muestra los posts de los usuarios. Hay una línea vertical tenue en el lado izquierdo que atraviesa los avatares para simular un "hilo" continuo.
3. Diseño del Post:
   - Fila superior: Avatar del usuario, Nombre en negrita, hora (ej. "2:09 pm") en gris tenue, y un ícono de "más opciones" (...).
   - Cuerpo del texto: Pregunta del usuario (ej. "Error de sintaxis en bucle For?").
   - Fragmento de código o Imagen adjunta: Un contenedor con fondo más oscuro (`#0F172A`), bordes redondeados y texto en fuente Monospace simulando código con syntax highlighting básico (colores distintos para palabras reservadas).
   - Barra de acciones (bottom del post): Íconos de Responder, Like (corazón) y Guardar (marcador) distribuidos horizontalmente.

Genera el código completo (ej. `forum_page.dart`) con datos de prueba, asegurándote de que el bloque de código se vea realista y bien formateado.

---

# Estado de implementación (TuEstadia)

Las tres pantallas del plan ya están programadas y conectadas a Firebase:

| Pantalla | Archivo | Estado |
|---|---|---|
| Home - Feed | `lib/features/feed/home_page.dart` | ✅ Completa |
| Biblioteca | `lib/features/library/library_page.dart` | ✅ Completa (con `CustomPainter` para la línea de tiempo) |
| Foro de Dudas | `lib/features/forum/forum_page.dart` | ✅ Completa (con syntax highlighting) |
| Navegación principal | `lib/features/shell/main_shell.dart` | ✅ Completa |
| Crear publicación | `lib/features/forum/create_post_page.dart` | ✅ Completa |
| Perfil | `lib/features/profile/profile_page.dart` | ✅ Completa |

La paleta Neo-Dark del plan está centralizada en `AppColors` (`lib/app_theme.dart`)
y el tema completo en `AppTheme.neoDark`:

```dart
AppColors.neoBackground  // #121826  Fondo principal
AppColors.neoSurface     // #1E293B  Fondo de tarjetas
AppColors.neoCyan        // #38BDF8  Acento primario
AppColors.neoEmerald     // #34D399  Acento secundario (éxito)
AppColors.neoSurfaceAlt  // #0F172A  Bloques de código
```

---

# Configuración de credenciales de Firebase

> **Pega aquí las credenciales** de tu proyecto de Firebase (o usa
> `flutterfire configure`, que regenera `lib/firebase_options.dart`).

```text
FIREBASE_API_KEY              =
FIREBASE_APP_ID               =
FIREBASE_MESSAGING_SENDER_ID  =
FIREBASE_PROJECT_ID           =
FIREBASE_AUTH_DOMAIN          =
FIREBASE_STORAGE_BUCKET       =
FIREBASE_WEB_APP_ID           =
FIREBASE_IOS_BUNDLE_ID        = com.example.tuestadia
FIREBASE_MACOS_BUNDLE_ID      = com.example.tuestadia
```

Estas mismas claves se pueden inyectar sin tocar código:

```bash
flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_PROJECT_ID=...
```

Mientras las credenciales no estén pegadas, la app arranca en **modo demo**
con datos de prueba (`lib/core/demo_data.dart`) y el enlace
**“Explorar en modo demo”** en el login.

## Colecciones en Firestore

| Colección | Campos |
|---|---|
| `projects` | `title`, `tech`, `imageUrl`, `authorName`, `authorAvatar`, `saved`, `createdAt` |
| `courses` | `title`, `subtitle`, `iconKey`, `colorValue`, `gradientStart`, `gradientEnd` |
| `chapters` | `courseId`, `title`, `chapterNumber`, `progress` |
| `posts` | `authorName`, `authorAvatar`, `question`, `code`, `likes`, `replies`, `saved`, `createdAt` |
| `profiles` | `displayName`, `email`, `photoUrl`, `bio` |

Guía completa de conexión: `FIREBASE_SETUP.md`.
