import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Barra inferior de herramientas del compositor (estilo Twitter).
class ForumComposerBar extends StatelessWidget {
  const ForumComposerBar({
    super.key,
    required this.onPickImages,
    required this.onTakePhoto,
    required this.onPickGif,
    required this.onAddPoll,
    required this.onAddLocation,
    required this.onToggleCode,
    this.enabled = true,
    this.hasPoll = false,
    this.hasLocation = false,
    this.hasCode = false,
  });

  final VoidCallback onPickImages;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickGif;
  final VoidCallback onAddPoll;
  final VoidCallback onAddLocation;
  final VoidCallback onToggleCode;
  final bool enabled;
  final bool hasPoll;
  final bool hasLocation;
  final bool hasCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neoSurface,
        border: Border(top: BorderSide(color: AppColors.neoBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              _ToolButton(
                icon: Icons.image_outlined,
                tooltip: 'Imagen o vídeo',
                onPressed: enabled ? onPickImages : null,
              ),
              _ToolButton(
                icon: Icons.photo_camera_outlined,
                tooltip: 'Tomar foto',
                onPressed: enabled ? onTakePhoto : null,
              ),
              _ToolButton(
                icon: Icons.gif_box_outlined,
                tooltip: 'GIF',
                onPressed: enabled ? onPickGif : null,
              ),
              _ToolButton(
                icon: Icons.bar_chart_rounded,
                tooltip: 'Encuesta',
                onPressed: enabled ? onAddPoll : null,
                active: hasPoll,
              ),
              _ToolButton(
                icon: Icons.location_on_outlined,
                tooltip: 'Ubicación',
                onPressed: enabled ? onAddLocation : null,
                active: hasLocation,
              ),
              _ToolButton(
                icon: Icons.code,
                tooltip: 'Bloque de código',
                onPressed: enabled ? onToggleCode : null,
                active: hasCode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: active ? AppColors.neoCyan : AppColors.neoTextMuted,
        disabledForegroundColor: AppColors.neoBorder,
      ),
      icon: Icon(icon, size: 21),
    );
  }
}
