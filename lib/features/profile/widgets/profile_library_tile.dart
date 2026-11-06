import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/drive_file.dart';
import '../../../core/models/library_item.dart';

/// Elemento de la biblioteca personal mostrado en el perfil.
class ProfileLibraryTile extends StatelessWidget {
  const ProfileLibraryTile({
    super.key,
    required this.item,
    this.onOpen,
    this.onRemove,
  });

  final LibraryItemModel item;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _buildPreview(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.categoryLabel} · ${item.readableSize}',
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar de mi biblioteca',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.bookmark_remove_outlined,
                  size: 19,
                  color: AppColors.neoTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final thumb = item.thumbnailUrl;
    if (item.isImage && thumb != null && thumb.isNotEmpty) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _icon(),
      );
    }
    return _icon();
  }

  Widget _icon() {
    return ColoredBox(
      color: AppColors.neoSurfaceAlt,
      child: Icon(_iconFor(item.category), color: AppColors.neoCyan, size: 24),
    );
  }

  static IconData _iconFor(DriveFileCategory category) {
    switch (category) {
      case DriveFileCategory.folder:
        return Icons.folder_rounded;
      case DriveFileCategory.pdf:
        return Icons.picture_as_pdf_rounded;
      case DriveFileCategory.image:
        return Icons.image_rounded;
      case DriveFileCategory.document:
        return Icons.description_rounded;
      case DriveFileCategory.spreadsheet:
        return Icons.table_chart_rounded;
      case DriveFileCategory.presentation:
        return Icons.slideshow_rounded;
      case DriveFileCategory.other:
        return Icons.insert_drive_file_rounded;
    }
  }
}
