import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/project.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/network_cover.dart';

/// Tarjeta de proyecto del feed principal.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onToggleSave,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: NetworkCover(
                  imageUrl: project.imageUrl,
                  height: 96,
                  icon: _iconForTech(project.tech),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 6),
              _TechLabel(tech: project.tech),
              const Spacer(),
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
                  const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.neoTextMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _BookmarkButton(
                    saved: project.saved,
                    onPressed: onToggleSave,
                  ),
                ],
              ),
            ],
          ),
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
        color: AppColors.neoCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neoCyan.withValues(alpha: 0.35),
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
    return InkResponse(
      onTap: onPressed,
      radius: 20,
      child: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        size: 19,
        color: saved ? AppColors.neoEmerald : AppColors.neoTextMuted,
      ),
    );
  }
}
