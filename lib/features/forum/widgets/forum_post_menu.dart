import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Menú "…" de una publicación.
class ForumPostMenu extends StatelessWidget {
  const ForumPostMenu({
    super.key,
    required this.isOwner,
    required this.onCopyLink,
    required this.onDelete,
  });

  final bool isOwner;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PostAction>(
      tooltip: 'Más opciones',
      color: AppColors.neoSurface,
      icon: const Icon(
        Icons.more_horiz,
        size: 20,
        color: AppColors.neoTextMuted,
      ),
      onSelected: (action) {
        switch (action) {
          case _PostAction.copyLink:
            onCopyLink();
          case _PostAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PostAction.copyLink,
          child: Row(
            children: [
              Icon(Icons.link, size: 18, color: AppColors.neoTextMuted),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Copiar enlace',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        if (isOwner)
          const PopupMenuItem(
            value: _PostAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Eliminar publicación',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _PostAction { copyLink, delete }
