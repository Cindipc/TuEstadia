import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_poll.dart';

/// Encuesta adjunta a un post, con votación y resultados en vivo.
class ForumPollWidget extends StatelessWidget {
  const ForumPollWidget({
    super.key,
    required this.poll,
    required this.onVote,
    this.currentUserId,
    this.voting = false,
  });

  final ForumPollModel poll;
  final ValueChanged<String> onVote;
  final String? currentUserId;
  final bool voting;

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasVotedBy(currentUserId);
    final total = poll.totalVotes;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in poll.options) ...[
            _buildOption(context, option, hasVoted),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 14,
                color: AppColors.neoTextMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '$total ${total == 1 ? 'voto' : 'votos'}',
                style: const TextStyle(
                  color: AppColors.neoTextMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!hasVoted)
                const Text(
                  'Toca para votar',
                  style: TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    ForumPollOption option,
    bool hasVoted,
  ) {
    final percent = (poll.percentageOf(option) * 100).round();
    final mine = option.hasVoteFrom(currentUserId);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: voting ? null : () => onVote(option.id),
        child: Stack(
          children: [
            if (hasVoted)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: poll.percentageOf(option).clamp(0.0, 1.0),
                  child: ColoredBox(
                    color: mine
                        ? AppColors.neoCyan.withValues(alpha: 0.28)
                        : AppColors.neoBorder.withValues(alpha: 0.55),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: mine ? AppColors.neoCyan : AppColors.neoBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mine ? AppColors.neoCyan : Colors.white,
                        fontSize: 13,
                        fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasVoted) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: mine ? AppColors.neoCyan : AppColors.neoTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
