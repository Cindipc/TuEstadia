import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_theme.dart';
import '../../../core/firebase_bootstrap.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/utils/forum_interactions.dart';
import '../screens/post_detail_page.dart';
import 'forum_empty_state.dart';
import 'forum_thread_item.dart';

/// Lista de publicaciones con like, guardado, encuesta, eliminar y navegación
/// al detalle. Se reutiliza en el foro, la búsqueda y las tendencias.
class ForumPostList extends StatefulWidget {
  const ForumPostList({
    super.key,
    required this.posts,
    required this.repository,
    required this.currentUserId,
    this.replyCounts = const {},
    this.emptyState,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
  });

  final List<ForumPostModel> posts;
  final ForumRepository repository;
  final String? currentUserId;
  final Map<String, int> replyCounts;
  final Widget? emptyState;
  final EdgeInsets padding;

  @override
  State<ForumPostList> createState() => _ForumPostListState();
}

class _ForumPostListState extends State<ForumPostList> {
  final Map<String, ForumPostModel> _pending = {};
  String? _votingPostId;

  @override
  void didUpdateWidget(covariant ForumPostList oldWidget) {
    super.didUpdateWidget(oldWidget);
    pruneConfirmed(_pending, widget.posts);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ForumPostModel _visible(ForumPostModel post) => _pending[post.id] ?? post;

  Future<void> _toggleLike(ForumPostModel post) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      _showMessage('Inicia sesión para dar like.');
      return;
    }

    final liked = post.isLikedBy(uid);
    setState(() {
      _pending[post.id] = post.copyWith(
        likedBy: liked
            ? post.likedBy.where((id) => id != uid).toList(growable: false)
            : [...post.likedBy, uid],
        likes: (post.likes + (liked ? -1 : 1)).clamp(0, 1 << 31),
      );
    });

    final ok = await widget.repository.toggleLike(post, uid);
    if (!mounted || ok) return;

    if (FirebaseBootstrap.isAvailable) {
      setState(() => _pending.remove(post.id));
      _showMessage(
        'No se pudo guardar el like. Revisa tu sesión y las reglas de Firestore.',
      );
    } else {
      _showMessage('Modo demo: el like no se guarda.');
    }
  }

  Future<void> _toggleSave(ForumPostModel post) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      _showMessage('Inicia sesión para guardar publicaciones.');
      return;
    }

    final saved = post.isSavedBy(uid);
    setState(() {
      _pending[post.id] = post.copyWith(
        savedBy: saved
            ? post.savedBy.where((id) => id != uid).toList(growable: false)
            : [...post.savedBy, uid],
        saved: !saved,
      );
    });

    final ok = await widget.repository.toggleSave(post, uid);
    if (!mounted || ok) return;

    if (FirebaseBootstrap.isAvailable) {
      setState(() => _pending.remove(post.id));
      _showMessage(
        'No se pudo guardar. Revisa tu sesión y las reglas de Firestore.',
      );
    } else {
      _showMessage('Modo demo: el cambio no se guarda.');
    }
  }

  Future<void> _vote(ForumPostModel post, String optionId) async {
    final uid = widget.currentUserId;
    if (uid == null) {
      _showMessage('Inicia sesión para votar.');
      return;
    }
    final poll = post.poll;
    if (poll == null || _votingPostId != null) return;

    setState(() {
      _votingPostId = post.id;
      _pending[post.id] = post.copyWith(poll: poll.vote(optionId, uid));
    });

    final updated = await widget.repository.voteInPoll(post.id, optionId, uid);
    if (!mounted) return;
    setState(() => _votingPostId = null);

    if (updated == null) {
      setState(() => _pending.remove(post.id));
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo registrar el voto. Revisa tu sesión y las reglas.'
            : 'Modo demo: el voto no se guarda.',
      );
    }
  }

  Future<void> _confirmDelete(ForumPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neoSurface,
        title: const Text(
          '¿Eliminar publicación?',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const Text(
          'Esta acción no se puede deshacer. También se eliminarán sus '
          'respuestas.',
          style: TextStyle(color: AppColors.neoTextMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await widget.repository.deletePost(post.id);
    if (!mounted) return;

    if (!ok) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo eliminar la publicación.'
            : 'Modo demo: no se puede eliminar.',
      );
      return;
    }
    _showMessage('Publicación eliminada');
  }

  void _copyLink(ForumPostModel post) {
    Clipboard.setData(
      ClipboardData(text: 'https://tuestadia.app/foro/${post.id}'),
    );
    _showMessage('Enlace copiado');
  }

  void _openThread(ForumPostModel post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailPage(post: post, repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return widget.emptyState ??
          const ForumEmptyState(
            icon: Icons.forum_outlined,
            title: 'No hay publicaciones',
            message: 'Sé el primero en publicar en el foro.',
          );
    }

    return ListView.separated(
      padding: widget.padding,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final post = _visible(widget.posts[index]);
        final uid = widget.currentUserId;

        return ForumThreadItem(
          post: post,
          isLast: index == widget.posts.length - 1,
          currentUserId: uid,
          replyCount: widget.replyCounts[post.id] ?? post.replies,
          votingPoll: _votingPostId == post.id,
          onLike: () => _toggleLike(post),
          onSave: () => _toggleSave(post),
          onReply: () => _openThread(post),
          onTap: () => _openThread(post),
          onDelete: post.isOwnedBy(uid) ? () => _confirmDelete(post) : null,
          onCopyLink: () => _copyLink(post),
          onVote: (optionId) => _vote(post, optionId),
        );
      },
    );
  }
}
