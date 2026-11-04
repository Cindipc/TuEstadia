import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_media.dart';

/// Celda de una imagen, vídeo o GIF adjunto.
class ForumMediaTile extends StatelessWidget {
  const ForumMediaTile({
    super.key,
    required this.media,
    this.onTap,
    this.borderRadius = 12,
  });

  final ForumMediaModel media;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: AppColors.neoSurfaceAlt,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildContent(),
              if (media.type != ForumMediaType.image) _buildBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (media.isVideo) {
      final thumbnail = media.thumbnailUrl;
      if (thumbnail == null || thumbnail.isEmpty) {
        return const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white70,
            size: 44,
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: thumbnail,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ColoredBox(
              color: AppColors.neoSurfaceAlt,
            ),
            errorWidget: (_, _, _) => const ColoredBox(
              color: AppColors.neoSurfaceAlt,
            ),
          ),
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 44,
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.neoSurfaceAlt),
      errorWidget: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.neoTextMuted),
      ),
    );
  }

  Widget _buildBadge() {
    final isVideo = media.isVideo;
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_outlined : Icons.gif_box_outlined,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isVideo ? 'Vídeo' : 'GIF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
