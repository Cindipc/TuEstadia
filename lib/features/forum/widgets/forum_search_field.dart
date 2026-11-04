import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Campo de búsqueda redondeado estilo Twitter.
class ForumSearchField extends StatelessWidget {
  const ForumSearchField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.hint = 'Buscar en el foro',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final bool autofocus;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 19, color: AppColors.neoTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.neoCyan,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.neoTextMuted,
                  fontSize: 14.5,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 8);
              return IconButton(
                tooltip: 'Limpiar',
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
                icon: const Icon(
                  Icons.close,
                  size: 17,
                  color: AppColors.neoTextMuted,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
