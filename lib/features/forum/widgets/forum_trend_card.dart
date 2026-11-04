import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_trend.dart';

/// Elemento de la lista de tendencias.
class ForumTrendCard extends StatelessWidget {
  const ForumTrendCard({
    super.key,
    required this.rank,
    required this.trend,
    this.onTap,
  });

  final int rank;
  final ForumTrend trend;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _kindLabel(trend.kind),
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trend.displayTerm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trend.postCount} ${trend.postCount == 1 ? 'publicación' : 'publicaciones'} · '
                      '${trend.engagement} interacciones',
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neoCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trend.score.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.neoCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.neoTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _kindLabel(ForumTrendKind kind) {
    return switch (kind) {
      ForumTrendKind.hashtag => 'Tendencia',
      ForumTrendKind.technology => 'Tema',
      ForumTrendKind.author => 'Persona',
    };
  }
}
