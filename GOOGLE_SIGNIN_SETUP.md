# Google Sign-In — configuración aplicada

El botón **Google** de `LoginPage` ya está conectado a Firebase Auth. En Android
abre el selector nativo de cuentas, obtiene el `idToken` y lo intercambia por una
sesión de Firebase. En web usa el popup de Firebase Auth.

## Estado actual

| Dato | Valor |
|---|---|
| Proyecto Firebase | `fwitter-7596d` |
| Paquete Android | `io.github.cindipc.tuestadia` |
| App Android registrada | `1:855255390470:android:459a1b5fa20f7be9d96687` |
| SHA-1 debug | `cd:6b:82:f8:4a:50:dd:66:9a:c6:65:11:88:d5:9b:b4:3c:dc:62:54` |
| SHA-1 release (upload key) | `40:20:ed:cd:61:29:fa:ea:1a:e4:ba:2e:50:11:6f:fb:da:e7:29:2b` |
| SHA-1 de Play App Signing | Pendiente: se obtiene en Play Console → App integrity |
| Cliente OAuth Web | `855255390470-qit6vifl2o2o34235gfa9i1n1sn84lq8.apps.googleusercontent.com` |
| Archivo Android | `android/app/google-services.json` |

Con estos cambios, el SHA-1 que antes estaba solo en
`com.thealphamerc.flutter_twitter_clone` también quedó asociado al paquete real
de la app. **No cambies el `applicationId` de Android** salvo que registres el
nuevo paquete en Firebase.

## Lo que falta en la consola (solo si no está hecho)

1. **Authentication → Sign-in method → Google**: debe estar habilitado.
2. Elige un **correo de asistencia del proyecto** y guarda.
3. En **Project settings → Your apps → TuEstadia (android)** verifica que
   aparezcan el SHA-1 de debug y el de release.
4. Cuando Play Console te muestre el **SHA-1 de la App signing key**, agrégalo
   también a esa misma app de Firebase y vuelve a descargar
   `android/app/google-services.json`. Sin ese paso, Google Sign-In fallará
   únicamente en la versión instalada desde Play.

El proveedor de Google necesita ese SHA-1 para aceptar la app. Si cambias de
computadora o compilas en release, agrega también el SHA-1 de esa firma:

```bash
cd android
./gradlew signingReport
```

Copia el `SHA1` de la variante `debug` o `release` y agrégalo en la misma app de
Firebase. La app ya no depende de que `google-services.json` contenga el SHA-1:
el cliente OAuth Web se pasa explícitamente desde
`lib/core/config/google_auth_config.dart`.

## Cómo funciona en el código

- `lib/core/auth_service.dart` → `AuthService.signInWithGoogle()`.
- `lib/core/config/google_auth_config.dart` → cliente OAuth Web/iOS.
- `lib/login_page.dart` → botón con estado de carga y mensajes de error.
- `android/app/build.gradle.kts` y `android/settings.gradle.kts` → plugin
  `com.google.gms.google-services` (genera `default_web_client_id`).
- `lib/firebase_options.dart` → app Android nueva.

## Sobrescribir los clientes OAuth

Los valores del proyecto ya vienen por defecto. Si usas otro proyecto de
Firebase, define:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=TU_CLIENTE_WEB.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=TU_CLIENTE_IOS.apps.googleusercontent.com
```

También puedes ponerlos en `.env` o en `dart_defines.json`.

## iOS / macOS

El código soporta iOS/macOS, pero falta el `GoogleService-Info.plist` y el URL
scheme del cliente iOS. Mientras no se agreguen, usa Android o web para probar
Google Sign-In. El bundle actual de iOS es `com.example.tuestadia`, pero el
cliente iOS registrado es `com.example.fwitterReborn`; hay que registrar una app
iOS con el bundle correcto o cambiar el bundle del proyecto.

## Web

El botón usa `signInWithPopup` de Firebase Auth. Solo asegúrate de que el
dominio desde el que sirves la app esté en **Authentication → Settings →
Authorized domains**.
