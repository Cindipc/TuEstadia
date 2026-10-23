import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/models/forum_post.dart';
import '../../core/repositories/forum_repository.dart';
import '../../core/widgets/app_avatar.dart';
import 'create_post_page.dart';
import 'widgets/forum_post_card.dart';

/// Pantalla "Foro de Dudas".
class ForumPage extends StatefulWidget {
  const ForumPage({super.key, this.repository});

  final ForumRepository? repository;

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late final ForumRepository _repository;
  late final Stream<List<ForumPostModel>> _posts;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
    _posts = _repository.watchPosts();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreatePost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (created == true && mounted) {
      _showMessage('Publicación creada en el foro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: AppAvatar(
              imageUrl: 'https://i.pravatar.cc/120?img=45',
              name: 'Tu Estadia',
              size: 34,
              borderColor: AppColors.neoCyan.withValues(alpha: 0.6),
              borderWidth: 1.5,
            ),
          ),
        ),
        title: const Text('Foro de Dudas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FloatingActionButton.small(
              heroTag: 'forum-create-post',
              backgroundColor: AppColors.neoCyan,
              foregroundColor: const Color(0xFF06232E),
              elevation: 0,
              tooltip: 'Crear publicación',
              onPressed: _openCreatePost,
              child: const Icon(Icons.edit_rounded, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ForumPostModel>>(
          stream: _posts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.neoCyan),
              );
            }

            final posts = snapshot.data ?? const <ForumPostModel>[];
            if (posts.isEmpty) {
              return const Center(
                child: Text(
                  'Todavía no hay preguntas en el foro.',
                  style: TextStyle(color: AppColors.neoTextMuted),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              physics: const BouncingScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _ThreadItem(
                  post: post,
                  isLast: index == posts.length - 1,
                  onLike: () => _repository.toggleLike(post),
                  onSave: () => _repository.toggleSave(post),
                  onReply: () => _showMessage('Respondiendo a ${post.authorName}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Envuelve la tarjeta con la línea vertical del hilo.
///
/// El avatar vive en la columna izquierda y la línea se dibuja justo por
/// detrás de él, de modo que el hilo parece continuo.
class _ThreadItem extends StatelessWidget {
  const _ThreadItem({
    required this.post,
    required this.isLast,
    required this.onLike,
    required this.onSave,
    required this.onReply,
  });

  final ForumPostModel post;
  final bool isLast;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onReply;

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
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppAvatar(
                  imageUrl: post.authorAvatar,
                  name: post.authorName,
                  size: 38,
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
          ),
        ),
      ],
    );
  }
}

/// Línea vertical tenue que atraviesa los avatares del hilo.
class ThreadLinePainter extends CustomPainter {
  const ThreadLinePainter({required this.color, this.drawBottom = true});

  final Color color;
  final bool drawBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const centerX = 26.0;
    const startY = 21.0;
    final endY = drawBottom ? size.height : size.height / 2;

    canvas.drawLine(
      Offset(centerX, startY),
      Offset(centerX, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ThreadLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.drawBottom != drawBottom;
  }
}
