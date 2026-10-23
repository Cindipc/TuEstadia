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
| `posts` | `authorName`, `authorAvatar`, `question`, `code`, `likes`, `replies`, `saved`, `createdAt` |
| `profiles` | `displayName`, `email`, `photoUrl`, `bio`, `updatedAt` |

`iconKey` admite: `python`, `flutter`, `database`, `git`, `algorithm`, `code`.

---

## 4. Autenticación

El login usa **Firebase Auth con email y contraseña**:

- **Ingresar** → `signInWithEmailAndPassword`
- **Regístrate** → `createUserWithEmailAndPassword` + documento en `profiles`
- **¿Olvidaste tu contraseña?** → `sendPasswordResetEmail`
- **Cerrar sesión** (Perfil) → `signOut`
- Modo demo disponible cuando Firebase no está disponible.

El botón de Google muestra un aviso: requiere configurar el proveedor OAuth
(Google) en Firebase Authentication y un `google-services.json` /
`GoogleService-Info.plist` con los SHA-1 registrados.

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
│   ├── auth_service.dart          # Login, registro, reset, logout
│   ├── seed_service.dart          # Sembrado de datos en Firestore
│   ├── demo_data.dart             # Datos de prueba
│   ├── stream_utils.dart          # Fallback de streams (vacío/error)
│   ├── models/
│   ├── repositories/
│   └── widgets/
└── features/
    ├── feed/home_page.dart        # Home - Feed
    ├── library/library_page.dart  # Biblioteca
    ├── forum/forum_page.dart      # Foro de Dudas
    ├── profile/profile_page.dart  # Perfil + estado de Firestore + seed
    └── shell/main_shell.dart      # Navegación inferior
```
