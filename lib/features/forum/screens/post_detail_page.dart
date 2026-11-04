import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../core/firebase_bootstrap.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/utils/forum_interactions.dart';
import '../widgets/forum_reply_bar.dart';
import '../widgets/forum_thread_item.dart';
import 'compose_post_page.dart';

/// Detalle de un hilo ("show"): publicación principal + respuestas + barra
/// para responder.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.post, this.repository});

  final ForumPostModel post;
  final ForumRepository? repository;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final ForumRepository _repository;
  StreamSubscription<List<ForumPostModel>>? _subscription;

  List<ForumPostModel> _all = const [];
  final Map<String, ForumPostModel> _pending = {};
  final FocusNode _replyFocus = FocusNode();
  bool _loading = true;
  String? _votingPostId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
    _subscription = _repository.watchPosts().listen(_onPosts);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = AuthService.currentUser?.uid;
      if (uid != null) _repository.addView(widget.post.id, uid);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _replyFocus.dispose();
    super.dispose();
  }

  void _onPosts(List<ForumPostModel> incoming) {
    if (!mounted) return;
    setState(() {
      _all = incoming;
      _loading = false;
      pruneConfirmed(_pending, incoming);
    });
  }

  /// uid con el que se registran likes: el real, o uno local en modo demo.
  String? get _interactionUid {
    final uid = AuthService.currentUser?.uid;
    if (uid != null) return uid;
    return FirebaseBootstrap.isAvailable ? null : 'demo-user';
  }

  ForumPostModel get _mainPost {
    final index = _all.indexWhere((post) => post.id == widget.post.id);
    final base = index == -1 ? widget.post : _all[index];
    return _pending[base.id] ?? base;
  }

  List<ForumPostModel> get _replies {
    final visible = applyPending(_all, _pending);
    return ForumRepository.repliesOf(visible, widget.post.id);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLike(ForumPostModel post) async {
    final uid = _interactionUid;
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

    final ok = await _repository.toggleLike(post, uid);
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
    final uid = _interactionUid;
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

    final ok = await _repository.toggleSave(post, uid);
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
    final uid = _interactionUid;
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

    final updated = await _repository.voteInPoll(post.id, optionId, uid);
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

    final ok = await _repository.deletePost(post.id);
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
    if (post.id == widget.post.id) {
      Navigator.of(context).maybePop();
    }
  }

  void _copyLink(ForumPostModel post) {
    Clipboard.setData(
      ClipboardData(text: 'https://tuestadia.app/foro/${post.id}'),
    );
    _showMessage('Enlace copiado');
  }

  Future<bool> _sendReply(String text) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'Inicia sesión para responder en el foro.'
            : 'Modo demo: las respuestas no se guardan.',
      );
      return false;
    }

    final ok = await _repository.createPost(
      question: text,
      code: '',
      authorId: uid,
      authorName: AuthService.displayName,
      authorAvatar: AuthService.photoUrl ?? '',
      parentPostId: widget.post.id,
    );
    if (!mounted) return false;

    if (!ok) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo publicar la respuesta. Revisa tu sesión y las '
                  'reglas de Firestore.'
            : 'Modo demo: la respuesta no se guarda.',
      );
      return false;
    }

    _showMessage('Respuesta publicada');
    return true;
  }

  void _focusComposer() {
    _replyFocus.requestFocus();
  }

  Future<void> _openCompose() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposePostPage(parentPost: _mainPost),
      ),
    );
    if (created == true && mounted) {
      _showMessage('Respuesta publicada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainPost = _mainPost;
    final replies = _replies;
    final uid = _interactionUid;

    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Publicación'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neoCyan,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ForumThreadItem(
                          post: mainPost,
                          isLast: replies.isEmpty,
                          avatarSize: 42,
                          currentUserId: uid,
                          replyCount: replies.length,
                          votingPoll: _votingPostId == mainPost.id,
                          onLike: () => _toggleLike(mainPost),
                          onSave: () => _toggleSave(mainPost),
                          onReply: _focusComposer,
                          onTap: _focusComposer,
                          onDelete: mainPost.isOwnedBy(uid)
                              ? () => _confirmDelete(mainPost)
                              : null,
                          onCopyLink: () => _copyLink(mainPost),
                          onVote: (optionId) => _vote(mainPost, optionId),
                        ),
                        _buildViews(mainPost),
                        const SizedBox(height: 8),
                        if (replies.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 18),
                            child: Text(
                              'Todavía no hay respuestas. ¡Sé el primero en '
                              'ayudar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.neoTextMuted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          )
                        else
                          ...List.generate(replies.length, (index) {
                            final reply = replies[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 10,
                              ),
                              child: ForumThreadItem(
                                post: reply,
                                isLast: index == replies.length - 1,
                                showReplyAction: false,
                                currentUserId: uid,
                                onLike: () => _toggleLike(reply),
                                onSave: () => _toggleSave(reply),
                                onReply: _focusComposer,
                                onTap: _focusComposer,
                                onDelete: reply.isOwnedBy(uid)
                                    ? () => _confirmDelete(reply)
                                    : null,
                                onCopyLink: () => _copyLink(reply),
                                onVote: (optionId) => _vote(reply, optionId),
                              ),
                            );
                          }),
                      ],
                    ),
            ),
            ForumReplyBar(
              focusNode: _replyFocus,
              hint: 'Responde a ${mainPost.authorName}…',
              onSend: _sendReply,
              onExpand: () {
                if (AuthService.currentUser == null) {
                  _showMessage('Inicia sesión para responder en el foro.');
                  return;
                }
                _openCompose();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViews(ForumPostModel post) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, top: 10),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 14,
            color: AppColors.neoTextMuted,
          ),
          const SizedBox(width: 6),
          Text(
            '${post.views.length} ${post.views.length == 1 ? 'vista' : 'vistas'}',
            style: const TextStyle(
              color: AppColors.neoTextMuted,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
