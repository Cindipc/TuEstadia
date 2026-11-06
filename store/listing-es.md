# Ficha de Google Play — TuEstadia

## Datos técnicos

| Campo | Valor |
|---|---|
| Nombre del paquete | `io.github.cindipc.tuestadia` |
| App ID Firebase | `1:855255390470:android:459a1b5fa20f7be9d96687` |
| Versión | `1.0.0+1` (versionCode 1) |
| SHA-1 debug | `cd:6b:82:f8:4a:50:dd:66:9a:c6:65:11:88:d5:9b:b4:3c:dc:62:54` |
| SHA-1 release (upload key) | `40:20:ed:cd:61:29:fa:ea:1a:e4:ba:2e:50:11:6f:fb:da:e7:29:2b` |
| SHA-1 Play App Signing | Se obtiene en Play Console → Release → Setup → App integrity |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

> **Importante:** después de activar Play App Signing, agrega el SHA-1 de la
> *App signing key* a Firebase y vuelve a descargar `google-services.json`.
> Sin ese paso, Google Sign-In fallará solo en la versión instalada desde Play.

## Ficha de la tienda

**Nombre (máx. 30):**
```
TuEstadia
```

**Descripción corta (máx. 80):**
```
Aprende programación en comunidad: proyectos, biblioteca y foro de dudas.
```

**Descripción completa (máx. 4000):**
```
TuEstadia es una comunidad para estudiantes de programación que quieren aprender haciendo.

En TuEstadia puedes:
• Descubrir proyectos y recursos compartidos por otros estudiantes.
• Guardar tus proyectos favoritos y organizar tu biblioteca personal.
• Publicar dudas en el foro con código, imágenes, vídeos, encuestas y etiquetas.
• Responder, reaccionar y guardar publicaciones de la comunidad.
• Personalizar tu perfil con tu nombre, biografía, foto y portada.

La app está pensada para acompañarte mientras aprendes: comparte lo que sabes, pregunta sin miedo y encuentra inspiración en lo que otros están construyendo.

TuEstadia no muestra anuncios. Puedes eliminar tu cuenta y tus datos en cualquier momento desde Perfil → menú → Eliminar cuenta.
```

**Categoría:** Educación

**Correo de contacto:** configúralo con el correo real del desarrollador en Play Console.

**Sitio web:** `https://fwitter-7596d.web.app/`

**Política de privacidad:** `https://fwitter-7596d.web.app/privacy-policy.html`

**Términos de uso:** `https://fwitter-7596d.web.app/terms.html`

**Eliminación de cuenta:** `https://fwitter-7596d.web.app/account-deletion.html`

## Recursos gráficos

| Recurso | Archivo | Estado |
|---|---|---|
| Icono 512×512 | `store/icon-512.png` | ✅ Generado |
| Feature graphic 1024×500 | `store/feature-graphic-1024x500.png` | ✅ Generado |
| Capturas de teléfono (mín. 2) | `store/screenshots/` | ⏳ Capturar en dispositivo real |
| Capturas de tablet (opcional) | `store/screenshots/` | Opcional |

Captura las pantallas con la app en un dispositivo real o emulador:
1. Login.
2. Registro (con el botón de Google y la aceptación de términos).
3. Feed de proyectos.
4. Foro de dudas.
5. Perfil.

Usa formato vertical 1080×1920 (9:16) o 1920×1080 (16:9), sin marcos ni texto
superpuesto que Google pueda considerar engañoso.

## Formularios de Play Console

- **Data safety:** la app recopila email, nombre, foto, contenido publicado,
  imágenes/vídeos y actividad. Cifrado en tránsito: sí. Se puede solicitar
  eliminación: sí. No se venden datos ni se usan para publicidad.
- **Anuncios:** no contiene anuncios.
- **Público objetivo:** 18+ (por el foro con contenido generado por usuarios).
- **Clasificación de contenido:** completar el cuestionario; sin violencia,
  sexo, drogas ni apuestas. El foro es moderado.
- **Acceso de la app:** la app requiere iniciar sesión. Proporciona a los
  revisores un usuario de prueba (correo y contraseña) y los pasos para entrar.
- **Contenido generado por usuarios:** términos públicos, reporte de posts,
  bloqueo de usuarios y moderación desde Firestore/consola.
- **Eliminación de cuenta:** en la app y en la URL pública de eliminación.
- **Noticias:** no es una app de noticias.
- **Salud / finanzas / gobierno:** no aplica.

## Orden de publicación

1. Subir el AAB a **Internal testing**.
2. Probar Google Sign-In con el build de Play (SHA-1 de App Signing registrado).
3. Crear **Closed testing** con al menos 12 testers durante 14 días.
4. Solicitar acceso a producción.
5. Rollout gradual: 10 % → 50 % → 100 %.
