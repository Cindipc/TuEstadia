import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app_theme.dart';

/// Reproductor de vídeo para los adjuntos del foro.
class ForumVideoView extends StatefulWidget {
  const ForumVideoView({super.key, required this.url, this.autoPlay = true});

  final String url;
  final bool autoPlay;

  @override
  State<ForumVideoView> createState() => _ForumVideoViewState();
}

class _ForumVideoViewState extends State<ForumVideoView> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      if (widget.autoPlay) await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.neoSurfaceAlt,
          child: Center(
            child: Text(
              'No se pudo reproducir el vídeo',
              style: TextStyle(color: AppColors.neoTextMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_ready || controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.neoSurfaceAlt,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.neoCyan,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: IconButton(
                tooltip: _muted ? 'Activar sonido' : 'Silenciar',
                onPressed: _toggleMute,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
