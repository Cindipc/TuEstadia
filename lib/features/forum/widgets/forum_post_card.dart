import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import 'code_block.dart';
import 'forum_media_grid.dart';
import 'forum_poll_widget.dart';
import 'forum_post_menu.dart';

/// Tarjeta de una publicación del foro.
class ForumPostCard extends StatelessWidget {
  const ForumPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onReply,
    this.onTap,
    this.currentUserId,
    this.replyCount,
    this.showReplyAction = true,
    this.onDelete,
    this.onCopyLink,
    this.onReport,
    this.onBlock,
    this.onVote,
    this.votingPoll = false,
  });

  final ForumPostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onReply;
  final VoidCallback? onTap;

  /// uid del usuario actual para pintar like/guardado y eliminar.
  final String? currentUserId;

  /// Contador de respuestas calculado por la pantalla.
  final int? replyCount;

  final bool showReplyAction;

  /// Eliminar (solo se muestra si el post es del usuario actual).
  final VoidCallback? onDelete;
  final VoidCallback? onCopyLink;

  /// Moderación de contenido de otros usuarios.
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  /// Votar en la encuesta.
  final ValueChanged<String>? onVote;
  final bool votingPoll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? onReply,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Text(
                post.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (post.hasMedia) ...[
                const SizedBox(height: 12),
                ForumMediaGrid(media: post.media),
              ],
              if (post.code.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                CodeBlock(code: post.code),
              ],
              if (post.poll != null) ...[
                const SizedBox(height: 12),
                ForumPollWidget(
                  poll: post.poll!,
                  currentUserId: currentUserId,
                  voting: votingPoll,
                  onVote: onVote ?? (_) {},
                ),
              ],
              if ((post.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.neoTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.neoTextMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isOwner = post.isOwnedBy(currentUserId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(
                  color: AppColors.neoTextMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ForumPostMenu(
          isOwner: isOwner && onDelete != null,
          onCopyLink: onCopyLink ?? () {},
          onDelete: onDelete ?? () {},
          onReport: onReport,
          onBlock: onBlock,
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final liked = post.isLikedBy(currentUserId);
    // Compatibilidad con documentos antiguos que solo guardaban `saved`.
    final saved =
        post.isSavedBy(currentUserId) || (post.savedBy.isEmpty && post.saved);

    return Wrap(
      spacing: 18,
      runSpacing: 4,
      children: [
        if (showReplyAction)
          _ActionButton(
            icon: Icons.mode_comment_outlined,
            label: 'Responder',
            count: replyCount ?? post.replies,
            onPressed: onReply,
          ),
        _ActionButton(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: 'Like',
          count: post.likes,
          color: liked ? AppColors.neoLike : null,
          onPressed: onLike,
        ),
        _ActionButton(
          icon: saved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Guardar',
          color: saved ? AppColors.neoEmerald : null,
          onPressed: onSave,
        ),
      ],
    );
  }

  static String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes.clamp(1, 59)} min';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final suffix = hours < 12 ? 'am' : 'pm';
      final hour12 = hours % 12 == 0 ? 12 : hours % 12;
      return '$hour12:${minutes.toString().padLeft(2, '0')} $suffix';
    }
    final days = difference.inDays;
    return days == 1 ? 'ayer' : 'hace $days días';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.count,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final int? count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.neoTextMuted;
    return InkResponse(
      onTap: onPressed,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 6),
            Text(
              count == null ? label : '$label · $count',
              style: TextStyle(
                color: effectiveColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
