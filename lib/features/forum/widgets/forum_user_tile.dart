import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_profile.dart';
import '../../../core/widgets/app_avatar.dart';

/// Fila de persona en los resultados de búsqueda.
class ForumUserTile extends StatelessWidget {
  const ForumUserTile({super.key, required this.profile, this.onTap});

  final ForumProfileModel profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: profile.photoUrl ?? '',
                name: profile.displayName,
                size: 44,
                borderColor: AppColors.neoCyan.withValues(alpha: 0.5),
                borderWidth: 1.5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email ?? 'Miembro de TuEstadia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${profile.activityCount} aportes',
                style: const TextStyle(
                  color: AppColors.neoCyan,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
