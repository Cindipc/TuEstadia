import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_media.dart';
import 'forum_media_tile.dart';
import 'forum_media_viewer.dart';

/// Rejilla de adjuntos de una publicación (1 a 4 elementos).
class ForumMediaGrid extends StatelessWidget {
  const ForumMediaGrid({super.key, required this.media});

  final List<ForumMediaModel> media;

  static const double _gap = 4;
  static const double _rowHeight = 170;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    final items = media.take(4).toList(growable: false);
    if (items.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ForumMediaTile(
          media: items.first,
          onTap: () => _openViewer(context, 0),
        ),
      );
    }

    if (items.length == 2) {
      return SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            Expanded(child: _tile(context, items[0], 0)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(context, items[1], 1)),
          ],
        ),
      );
    }

    if (items.length == 3) {
      return SizedBox(
        height: _rowHeight,
        child: Row(
          children: [
            Expanded(flex: 2, child: _tile(context, items[0], 0)),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _tile(context, items[1], 1)),
                  const SizedBox(height: _gap),
                  Expanded(child: _tile(context, items[2], 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, items[0], 0)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(context, items[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, items[2], 2)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(context, items[3], 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, ForumMediaModel item, int index) {
    return ForumMediaTile(
      media: item,
      onTap: () => _openViewer(context, index),
    );
  }

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForumMediaViewer(media: media, initialIndex: index),
      ),
    );
  }
}

/// Marco vacío con el color del tema para placeholders.
class ForumMediaPlaceholder extends StatelessWidget {
  const ForumMediaPlaceholder({super.key, this.height = 170});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.neoTextMuted,
          size: 28,
        ),
      ),
    );
  }
}
