import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Selector de dos o más opciones (p. ej. Pines / Posts).
class ProfileSegmented extends StatelessWidget {
  const ProfileSegmented({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: index == selectedIndex
                    ? AppColors.neoCyan.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: index == selectedIndex
                      ? AppColors.neoCyan
                      : AppColors.neoBorder,
                ),
              ),
              child: Text(
                options[index],
                style: TextStyle(
                  color: index == selectedIndex
                      ? AppColors.neoCyan
                      : AppColors.neoTextMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
