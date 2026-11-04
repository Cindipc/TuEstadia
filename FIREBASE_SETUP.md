# Configuración de Firebase — TuEstadia

Proyecto conectado: **`fwitter-7596d`**

La configuración ya está aplicada en `lib/firebase_options.dart` (generada por
FlutterFire CLI). No hace falta pegar credenciales.

---

## Estado verificado del proyecto

| Comprobación | Resultado |
|---|---|
| API key (REST) | ✅ válida |
| Firestore Database | ✅ existe |
| Auth → Email/Password | ✅ habilitado (`INVALID_LOGIN_CREDENTIALS`, no `OPERATION_NOT_ALLOWED`) |
| Reglas de Firestore | ⚠️ **deniegan lectura anónima (403)** — hay que publicarlas |

---

## 1. Publicar las reglas de Firestore  ⚠️ obligatorio

Sin esto, la app seguirá mostrando datos demo porque Firestore rechaza las
lecturas.

1. Abre el archivo [`firestore.rules`](firestore.rules) del repo.
2. En la consola: **Firestore Database → Rules** → pega el contenido →
   **Publish**.

Resumen de las reglas:

- Lectura pública de `projects`, `courses`, `chapters`, `posts` y `profiles`.
- Escritura solo con sesión iniciada.
- En `posts`, crear exige que `authorId` sea el uid del usuario; borrar solo
  permite al autor.
- Cada usuario solo escribe su propio documento en `profiles`.

---

## 2. Sembrar datos de prueba

Con las reglas publicadas y una sesión iniciada:

1. Entra a la app y regístrate o inicia sesión.
2. Ve a **Perfil → “Cargar datos de prueba en Firestore”**.

Esto crea los documentos de `lib/core/demo_data.dart` en Firestore (solo si las
colecciones están vacías). Después, la app deja de usar el respaldo demo y lee
directamente de la base de datos.

Alternativa: crear los documentos a mano desde la consola con los campos de la
tabla de abajo.

---

## 3. Colecciones y campos

| Colección | Campos |
|---|---|
| `projects` | `title`, `tech`, `imageUrl`, `authorName`, `authorAvatar`, `saved`, `createdAt` |
| `courses` | `title`, `subtitle`, `iconKey`, `colorValue`, `gradientStart`, `gradientEnd` |
| `chapters` | `courseId`, `title`, `chapterNumber`, `progress` |
| `posts` | `authorId`, `authorName`, `authorAvatar`, `question`, `code`, `media`, `tags`, `location`, `poll`, `likes`, `likedBy`, `replies`, `saved`, `savedBy`, `views`, `parentPostId`, `createdAt` |
| `profiles` | `displayName`, `email`, `photoUrl`, `bio`, `emailVerified`, `status`, `postsCount`, `repliesCount`, `savedCount`, `createdAt`, `updatedAt`, `verificationSentAt` |

`iconKey` admite: `python`, `flutter`, `database`, `git`, `algorithm`, `code`.

### Foro de dudas: hilos, media y tendencias

Mismo patrón de hilos que `fwitter_reborn`:

- Todas las publicaciones viven en `posts`; una raíz tiene `parentPostId: null`.
- Una respuesta es un documento de `posts` con `parentPostId = <id del padre>`.
- `likedBy`, `savedBy` y `views` son arrays de uids; `likes` es el contador
  desnormalizado. El like se alterna con `arrayUnion` / `arrayRemove`, así que
  se puede quitar y es por usuario.
- `media` guarda los adjuntos de Cloudinary:
  `[{type: image|video|gif, url, thumbnailUrl, publicId, width, height, bytes}]`.
- `tags` son las etiquetas (se derivan de los `#hashtags` del texto) y `poll`
  es la encuesta: `{options: [{id, text, votes: [uid]}]}`.
- Al publicar se guarda `authorId` y se actualiza `profiles/{uid}`
  (`postsCount` o `repliesCount`); al guardar, `savedCount`.
- El foro consulta `posts` con `orderBy('createdAt')` y separa raíces y
  respuestas en memoria: **no hacen falta índices compuestos**.
- `PostDetailPage` registra una vista al abrirse y permite responder desde la
  barra inferior. El botón "Ampliar" abre `ComposePostPage` con el padre.
- **Tendencias**: `ForumTrendEngine` puntúa hashtags, etiquetas y autores en el
  cliente con interacción ponderada y decaimiento temporal (vida media 18 h).
- **Eliminar**: solo el autor (`authorId == uid`); la regla de Firestore lo
  valida y el menú "…" solo muestra la opción en publicaciones propias.

### Multimedia con Cloudinary

- Configuración heredada de `fwitter_reborn` (preset *unsigned*):
  `cloud_name = xnnb3pfg`, `upload_preset = fwitter_preset` (verificado).
- Se puede sobreescribir sin tocar código:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=mi_cloud \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=mi_preset
```

- Límites del cliente: máximo **4 adjuntos** por publicación y **15 MB** por
  archivo (`MediaUploadService`).
- Formatos: imágenes, vídeos (`.mp4`, `.mov`, `.webm`…) y GIF. Los vídeos se
  suben con `video/upload` y se les genera una miniatura automática.
- En iOS/macOS están declarados `NSPhotoLibraryUsageDescription`,
  `NSCameraUsageDescription` y `NSMicrophoneUsageDescription`.
- El borrado del post **no** elimina el asset de Cloudinary: para eso hace falta
  una subida firmada con `api_secret` (recomendado para producción).

---

## 4. Autenticación

El login usa **Firebase Auth con email y contraseña**:

- **Ingresar** → `signInWithEmailAndPassword`
- **Regístrate** → pantalla `RegisterPage` (nombre, correo, contraseña y
  confirmación) → `createUserWithEmailAndPassword` + documento en `profiles`
- **¿Olvidaste tu contraseña?** → `sendPasswordResetEmail`
- **Cerrar sesión** (Perfil) → `signOut`
- Modo demo disponible cuando Firebase no está disponible.

El registro **no pide confirmar el correo**: la cuenta queda activa al crearse
(`status: 'active'`) y el usuario entra directo a la app.

El botón de Google muestra un aviso: requiere configurar el proveedor OAuth
(Google) en Firebase Authentication y un `google-services.json` /
`GoogleService-Info.plist` con los SHA-1 registrados.

---

## 4.1 Verificación de correo (preparada, apagada)

Todo el flujo está implementado, pero desactivado por defecto:

- `lib/core/auth_config.dart` → `AuthConfig.requireEmailVerification = false`.
- Con el flag **apagado**: no se envía ningún correo y el registro es inmediato.
- Con el flag **encendido**:
  - al registrarse se envía el correo de verificación y el perfil queda en
    `status: 'pending'`;
  - `_AuthGate` (`lib/main.dart`) bloquea el acceso con
    `EmailVerificationPage` hasta que `emailVerified` sea `true`;
  - esa pantalla permite **reenviar** (con espera de 60 s) y **ya verifiqué**.

Para activarlo, elige una opción:

```bash
# Sin tocar código
flutter run --dart-define=TUESTADIA_REQUIRE_EMAIL_VERIFICATION=true

# O cambia el valor por defecto en lib/core/auth_config.dart
```

Pasos recomendados al activarlo:

1. Revisa la plantilla en **Authentication → Templates → Email address
   verification** (remitente, asunto y enlace).
2. Si usas dominio propio en web, define `AuthConfig.verificationContinueUrl`.
3. Endurece `firestore.rules` añadiendo
   `&& request.auth.token.email_verified == true` a los `allow write`
   (hay un ejemplo comentado en el archivo).
4. Prueba con una cuenta real: registro → correo → verificar → volver a la app
   → «Ya verifiqué mi correo».

> El bloqueo de la pantalla es de la app. Para seguridad real (que nadie llame a
> la API saltándose la verificación), la condición de las reglas es la que
> manda.

---

## 5. Notas por plataforma

| Plataforma | Estado |
|---|---|
| **Web** | ✅ funciona con la config actual |
| **Windows** | ✅ usa la app web del proyecto |
| **Android** | ⚠️ el `applicationId` de la app es `com.example.tuestadia`; debe coincidir con una app Android registrada en el proyecto `fwitter-7596d` |
| **iOS / macOS** | ⚠️ el bundle del Runner es `com.example.tuestadia`, pero la config trae `iosBundleId: com.example.fwitterReborn`. Registra una app iOS/macOS con `com.example.tuestadia` o cambia el bundle del proyecto |
| **Linux** | ❌ Firebase no soportado; la app corre en modo demo |

Para registrar una app nueva: **Project settings → Your apps → Add app**.

---

## 6. Modo demo

Si no hay conexión, las reglas bloquean la lectura o la plataforma no soporta
Firebase, la app **no se rompe**: usa `lib/core/demo_data.dart` y muestra el
aviso de modo demo. Los cambios (guardar, like, publicar) no se persisten.

---

## 7. Estructura del código

```text
lib/
├── firebase_options.dart          # Credenciales (FlutterFire CLI)
├── core/
│   ├── firebase_bootstrap.dart    # Inicialización + fallback a demo
│   ├── auth_service.dart          # Login, registro, reset, logout, verificación
│   ├── auth_config.dart           # Flag de verificación de correo
│   ├── auth_error_messages.dart   # Errores de Auth en español
│   ├── seed_service.dart          # Sembrado de datos en Firestore
│   ├── demo_data.dart             # Datos de prueba
│   ├── stream_utils.dart          # Fallback de streams (vacío/error)
│   ├── models/                     # Project, Course, Chapter, ForumPost, Media, Poll, Trend, Profile
│   ├── repositories/               # Project, Library, Forum
│   ├── services/
│   │   ├── cloudinary_service.dart  # Subida de imágenes/vídeos/GIF
│   │   ├── media_upload_service.dart # Límites y subida de adjuntos
│   │   └── forum_trend_engine.dart  # Algoritmo de tendencias
│   ├── utils/forum_interactions.dart # Estado optimista del like
│   └── widgets/
└── features/
    ├── auth/
    │   ├── register_page.dart             # Registro (nombre, correo, 2 contraseñas)
    │   ├── email_verification_page.dart   # Confirmación de correo (preparada)
    │   └── auth_ui.dart                   # Estilos compartidos de auth
    ├── feed/home_page.dart        # Home - Feed
    ├── library/library_page.dart  # Biblioteca
    ├── forum/
    │   ├── forum_page.dart              # Recientes / Tendencias / Sin responder
    │   ├── screens/
    │   │   ├── compose_post_page.dart        # Escritura estilo Twitter + media
    │   │   ├── post_detail_page.dart         # Hilo + respuestas
    │   │   ├── forum_search_page.dart        # Búsqueda + sugerencias
    │   │   ├── forum_search_results_page.dart# Resultados con pestañas
    │   │   ├── forum_trends_page.dart        # Tendencias
    │   │   └── forum_filters_sheet.dart      # Filtros de búsqueda
    │   └── widgets/                          # Tarjetas, media, encuesta, compositor…
    ├── profile/profile_page.dart  # Perfil + estado de Firestore + seed
    └── shell/main_shell.dart      # Navegación inferior
```
