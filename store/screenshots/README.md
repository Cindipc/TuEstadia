# Capturas para Google Play

Google Play exige al menos **2 capturas** para teléfono. Recomendado: 5–8.

## Formato

- Vertical: 1080×1920 px (9:16) o horizontal: 1920×1080 px (16:9).
- PNG o JPEG, sin transparencias.
- Sin marcos de dispositivo, sin texto engañoso y sin contenido que no exista en la app.
- Mínimo 320 px y máximo 3840 px por lado.

## Qué capturar

1. `01-login.png` — pantalla de inicio de sesión.
2. `02-registro-google.png` — registro con Google y aceptación de términos.
3. `03-feed.png` — feed de proyectos.
4. `04-foro.png` — foro de dudas con publicaciones.
5. `05-perfil.png` — perfil de usuario.

## Cómo capturarlas

En un dispositivo Android real:

1. Instala el build de release o profile:
   `flutter install --release`
2. Navega a cada pantalla.
3. Captura con los botones físicos del dispositivo.
4. Pasa las imágenes a esta carpeta con los nombres indicados.

Alternativa con emulador:

```bash
flutter emulators --launch <emulador>
flutter run --release
adb exec-out screencap -p > store/screenshots/01-login.png
```

Si usas `adb`, repite el comando en cada pantalla.
