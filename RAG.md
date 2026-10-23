# Panel de Control RAG - Proyecto Principal

## Estado Actual

- **Fase Activa:** Fase 1 - Fundamentos (Arquitectura y UI).
- **Módulo en Desarrollo:** Layout Base y Rutas Secundarias.
- **Última Acción:** Reubicación estructural: `design.md` establecido en la raíz del proyecto para acceso global.

## Mapa de Conocimiento (Contexto)

- `[design.md]`: _(En raíz)_ Contiene la paleta de colores, tipografía, componentes globales, Layout Principal (App Shell) y el esquema de Pantallas Secundarias.
- `[docs/history/]`: Directorio de archivos históricos para el volcado del `auto-archiver`. _(Vacío actualmente)_

## Árbol de Directorios Actualizado (Fase 1)

```text
/
├── RAG.md                     # Fuente de verdad principal
├── design.md                  # Documentación global de UI/UX y Sistema de Diseño
├── docs/
│   └── history/               # Historial de fases completadas
└── src/
    ├── core/
    │   ├── theme/             # theme.dart, colors.dart, typography.dart
    │   └── routing/           # app_router.dart (Configuración de go_router y ShellRoute)
    ├── shared/
    │   ├── components/        # widgets/ (cards, buttons), layout/ (main_scaffold.dart)
    │   └── utils/
    └── features/
        ├── feed/              # Vistas: home_page.dart, project_detail_page.dart
        ├── library/           # Vistas: library_page.dart, reader_page.dart
        ├── forum/             # Vistas: forum_page.dart, thread_detail_page.dart, create_post_page.dart
        └── profile/           # Vistas: profile_page.dart, boards_page.dart
```
