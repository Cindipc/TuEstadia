import 'package:flutter/material.dart';

import '../../app_theme.dart';

/// Placeholder genérico de red para las portadas de los proyectos.
class NetworkCover extends StatelessWidget {
  const NetworkCover({
    super.key,
    required this.imageUrl,
    this.icon = Icons.code_rounded,
    this.height,
  });

  final String imageUrl;
  final IconData icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243049), Color(0xFF16203A)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 28, color: AppColors.neoCyan.withValues(alpha: 0.6)),
    );

    if (imageUrl.isEmpty) return placeholder;

    return Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
    );
  }
}
