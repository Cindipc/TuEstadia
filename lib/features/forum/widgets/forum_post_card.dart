import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import 'code_block.dart';

/// Tarjeta de una publicación del foro.
class ForumPostCard extends StatelessWidget {
  const ForumPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    required this.onReply,
  });

  final ForumPostModel post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onReply,
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
              if (post.code.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                CodeBlock(code: post.code),
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
        IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          color: AppColors.neoTextMuted,
          tooltip: 'Más opciones',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Wrap(
      spacing: 18,
      runSpacing: 4,
      children: [
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          label: 'Responder',
          count: post.replies,
          onPressed: onReply,
        ),
        _ActionButton(
          icon: post.likes > 0 ? Icons.favorite : Icons.favorite_border,
          label: 'Like',
          count: post.likes,
          color: post.likes > 0 ? const Color(0xFFF472B6) : null,
          onPressed: onLike,
        ),
        _ActionButton(
          icon: post.saved ? Icons.bookmark : Icons.bookmark_border,
          label: 'Guardar',
          color: post.saved ? AppColors.neoEmerald : null,
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
