import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/project.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/network_cover.dart';

/// Tarjeta de proyecto del feed principal (estilo Pinterest).
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onToggleSave,
    this.onDelete,
    this.imageHeight,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  /// Solo se pasa cuando el proyecto pertenece al usuario actual.
  final VoidCallback? onDelete;

  /// Altura de la imagen. Si es null, se elige una variada de forma estable
  /// a partir del título para lograr el efecto de cascada.
  final double? imageHeight;

  static const List<double> _heights = [170, 220, 260, 195, 240, 280];

  double get _resolvedHeight =>
      imageHeight ?? _heights[project.title.hashCode.abs() % _heights.length];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande a todo el ancho, con overlays.
            Stack(
              children: [
                NetworkCover(
                  imageUrl: project.imageUrl,
                  height: _resolvedHeight,
                  icon: _iconForTech(project.tech),
                ),
                // Etiqueta de tecnología abajo a la izquierda.
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _TechLabel(tech: project.tech),
                ),
                // Botón guardar arriba a la derecha.
                Positioned(
                  top: 8,
                  right: 8,
                  child: _BookmarkButton(
                    saved: project.saved,
                    onPressed: onToggleSave,
                  ),
                ),
                // Eliminar solo en publicaciones propias.
                if (onDelete != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _DeleteButton(onDelete: onDelete!),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppAvatar(
                        imageUrl: project.authorAvatar,
                        name: project.authorName,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neoTextMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForTech(String tech) {
    switch (tech.toLowerCase()) {
      case 'flutter':
      case 'dart':
        return Icons.flutter_dash;
      case 'node.js':
      case 'javascript':
        return Icons.javascript;
      case 'react':
        return Icons.widgets;
      case 'firebase':
        return Icons.local_fire_department;
      case 'python':
        return Icons.terminal;
      case 'kotlin':
        return Icons.android;
      case 'css':
        return Icons.palette;
      default:
        return Icons.code_rounded;
    }
  }
}

class _TechLabel extends StatelessWidget {
  const _TechLabel({required this.tech});

  final String tech;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neoCyan.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        tech,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.neoCyan,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            size: 19,
            color: saved ? AppColors.neoEmerald : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      color: AppColors.neoSurface,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 170),
      onSelected: (_) => onDelete(),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Eliminar',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_horiz, size: 19, color: Colors.white),
      ),
    );
  }
}