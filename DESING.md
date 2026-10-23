## 5. Estructura del Layout Principal (App Shell)

Todas las pantallas principales de la aplicación[cite: 2] vivirán dentro de un contenedor base o "Shell" para mantener el estado de navegación y la barra inferior consistente.

- **Componente Base:** `Scaffold` envolvente.
- **Bottom Navigation Bar:**
  - Estilo flotante o anclado al fondo con color `#1E293B`.
  - 4 Íconos principales: Home (Casa), Foro (Burbuja de chat), Biblioteca (Marcador/Libro), Perfil/Ajustes (Engranaje)[cite: 2].
  - Estado Activo: El ícono seleccionado se ilumina en Cyan (`#38BDF8`) y muestra un indicador visual (línea inferior)[cite: 2].
- **Gestión de Estado:** Se usará un `IndexedStack` o un enrutador avanzado (como `go_router` con `StatefulShellRoute`) para no perder la posición del scroll (por ejemplo, al cambiar de Webtoon a Twitter y regresar).

## 6. Pantallas Secundarias (Navegación Profunda)

A partir de las vistas principales, el sistema debe contemplar las siguientes pantallas secundarias (Rutas hijas):

### 6.1. Flujo Home - Feed

- **Vista: Detalle de Proyecto.** Al tocar una tarjeta del Feed.
  - _Layout:_ Imagen hero en la parte superior, título, descripción completa, listado de tecnologías, enlace a repositorio y botón principal de "Guardar en Tablero".

### 6.2. Flujo Biblioteca

- **Vista: Visor de Contenido (Lector).** Al tocar "Continuar leyendo"[cite: 2].
  - _Layout:_ Lectura en scroll vertical (estilo Webtoon). App bar minimalista que se oculta al hacer scroll, contenido enriquecido (Markdown o HTML), y botones de "Capítulo Anterior / Siguiente" al final.

### 6.3. Flujo Foro de Dudas

- **Vista: Hilo de Discusión (Detalle de Duda).** Al tocar un post en la línea de tiempo[cite: 2].
  - _Layout:_ Pregunta original expandida (con fragmento de código completo). Debajo, una lista de respuestas (comentarios) y un campo de texto fijo en la parte inferior del teclado para "Agregar una respuesta".
- **Vista: Crear Nueva Duda.** Al tocar el FAB (Floating Action Button) de lápiz azul en la esquina superior derecha[cite: 2].
  - _Layout:_ Formulario de pantalla completa. Input para título, área de texto grande, botones para adjuntar imagen y formatear fragmento de código.

### 6.4. Flujo Perfil/Ajustes

- **Vista: Mis Tableros / Perfil.** (Accesible desde el cuarto ícono del menú inferior).
  - _Layout:_ Información del usuario y tabs internos para alternar entre "Pines Guardados" y "Mis Publicaciones".
