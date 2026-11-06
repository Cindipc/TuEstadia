import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/widgets/app_avatar.dart';
import 'forum_post_card.dart';

/// Publicación con el avatar y la línea vertical del hilo.
///
/// Se usa tanto en el listado del foro como en la pantalla de detalle.
class ForumThreadItem extends StatelessWidget {
  const ForumThreadItem({
    super.key,
    required this.post,
    required this.isLast,
    required this.onLike,
    required this.onSave,
    required this.onReply,
    this.onTap,
    this.currentUserId,
    this.replyCount,
    this.showReplyAction = true,
    this.avatarSize = 38,
    this.onDelete,
    this.onCopyLink,
    this.onReport,
    this.onBlock,
    this.onVote,
    this.votingPoll = false,
  });

  final ForumPostModel post;
  final bool isLast;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onReply;
  final VoidCallback? onTap;
  final String? currentUserId;
  final int? replyCount;
  final bool showReplyAction;
  final double avatarSize;
  final VoidCallback? onDelete;
  final VoidCallback? onCopyLink;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final ValueChanged<String>? onVote;
  final bool votingPoll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ThreadLinePainter(
                    color: AppColors.neoBorder.withValues(alpha: 0.7),
                    drawBottom: !isLast,
                    avatarSize: avatarSize,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppAvatar(
                  imageUrl: post.authorAvatar,
                  name: post.authorName,
                  size: avatarSize,
                  borderColor: AppColors.neoCyan.withValues(alpha: 0.5),
                  borderWidth: 1.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ForumPostCard(
            post: post,
            onLike: onLike,
            onSave: onSave,
            onReply: onReply,
            onTap: onTap ?? onReply,
            currentUserId: currentUserId,
            replyCount: replyCount,
            showReplyAction: showReplyAction,
            onDelete: onDelete,
            onCopyLink: onCopyLink,
            onReport: onReport,
            onBlock: onBlock,
            onVote: onVote,
            votingPoll: votingPoll,
          ),
        ),
      ],
    );
  }
}

/// Línea vertical tenue que atraviesa los avatares del hilo.
class ThreadLinePainter extends CustomPainter {
  const ThreadLinePainter({
    required this.color,
    this.drawBottom = true,
    this.avatarSize = 38,
  });

  final Color color;
  final bool drawBottom;
  final double avatarSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const centerX = 26.0;
    final startY = avatarSize / 2 + 2;
    final endY = drawBottom ? size.height : startY + 1;

    canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant ThreadLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.drawBottom != drawBottom ||
        oldDelegate.avatarSize != avatarSize;
  }
}
