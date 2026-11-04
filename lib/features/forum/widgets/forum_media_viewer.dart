import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_media.dart';
import 'forum_video_view.dart';

/// Visor a pantalla completa de los adjuntos (swipe entre imágenes/vídeos).
class ForumMediaViewer extends StatefulWidget {
  const ForumMediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
  });

  final List<ForumMediaModel> media;
  final int initialIndex;

  @override
  State<ForumMediaViewer> createState() => _ForumMediaViewerState();
}

class _ForumMediaViewerState extends State<ForumMediaViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.media.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.media.length > 1
              ? '${_index + 1} de ${widget.media.length}'
              : 'Adjunto',
          style: const TextStyle(fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.media.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          final item = widget.media[index];
          if (item.isVideo) {
            return Center(child: ForumVideoView(url: item.url));
          }
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const CircularProgressIndicator(
                  color: AppColors.neoCyan,
                  strokeWidth: 2.5,
                ),
                errorWidget: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.neoTextMuted,
                  size: 42,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
