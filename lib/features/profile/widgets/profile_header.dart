import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/widgets/app_avatar.dart';

class ProfileStat {
  const ProfileStat({required this.label, required this.value});

  final String label;
  final int value;
}

/// Cabecera del perfil con portada, avatar, datos y acciones.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    this.bannerUrl,
    required this.stats,
    this.onTapBanner,
    this.isDemo = false,
  });

  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final String? bannerUrl;
  final List<ProfileStat> stats;
  final VoidCallback? onTapBanner;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTapBanner,
              child: Container(
                height: 96,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.neoCyan.withValues(alpha: 0.35),
                      AppColors.neoEmerald.withValues(alpha: 0.22),
                      AppColors.neoSurface,
                    ],
                  ),
                  border: Border.all(color: AppColors.neoBorder),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((bannerUrl ?? '').isNotEmpty)
                      Image.network(
                        bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    if ((bannerUrl ?? '').isNotEmpty)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.neoBackground.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      )
                    else
                      const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: AppColors.neoTextMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 26,
              top: 54,
              child: AppAvatar(
                imageUrl: photoUrl,
                name: name,
                size: 86,
                borderColor: AppColors.neoBackground,
                borderWidth: 3,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 48, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.neoTextMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Text(
            bio.trim().isEmpty
                ? 'Aprende, comparte y programa junto a otros.'
                : bio.trim(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: bio.trim().isEmpty
                  ? AppColors.neoTextMuted.withValues(alpha: 0.8)
                  : Colors.white,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        if (isDemo)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 14,
                  color: AppColors.neoTextMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Modo demo: los cambios no se guardan.',
                    style: const TextStyle(
                      color: AppColors.neoTextMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Row(
            children: [
              for (var index = 0; index < stats.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: _StatItem(stat: stats[index])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat});

  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${stat.value}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.neoTextMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
