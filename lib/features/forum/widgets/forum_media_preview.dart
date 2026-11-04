import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_media.dart';
import 'forum_media_tile.dart';

/// Previsualización de los adjuntos del compositor (con opción de quitar).
class ForumMediaPreview extends StatelessWidget {
  const ForumMediaPreview({
    super.key,
    required this.media,
    required this.onRemove,
    this.uploading = false,
  });

  final List<ForumMediaModel> media;
  final ValueChanged<int> onRemove;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length + (uploading ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index >= media.length) {
            return const _UploadingTile();
          }
          final item = media[index];
          return SizedBox(
            width: 104,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ForumMediaTile(media: item, borderRadius: 12),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    tooltip: 'Quitar',
                    onPressed: () => onRemove(index),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(26, 26),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.close, size: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.neoCyan,
            strokeWidth: 2.2,
          ),
        ),
      ),
    );
  }
}

/// Vista previa de un vídeo remoto (miniatura con icono de reproducción).
class ForumRemoteThumbnail extends StatelessWidget {
  const ForumRemoteThumbnail({
    super.key,
    required this.url,
    this.height = 104,
  });

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(color: AppColors.neoSurfaceAlt),
        errorWidget: (_, _, _) => const ColoredBox(
          color: AppColors.neoSurfaceAlt,
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.neoTextMuted,
          ),
        ),
      ),
    );
  }
}
