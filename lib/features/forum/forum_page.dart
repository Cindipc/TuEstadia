import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/models/forum_post.dart';
import '../../core/repositories/forum_repository.dart';
import '../../core/utils/forum_interactions.dart';
import '../../core/widgets/app_avatar.dart';
import 'screens/compose_post_page.dart';
import 'screens/forum_search_page.dart';
import 'screens/forum_trends_page.dart';
import 'widgets/forum_empty_state.dart';
import 'widgets/forum_post_list.dart';

/// Pantalla "Foro de Dudas": área principal con pestañas.
class ForumPage extends StatefulWidget {
  const ForumPage({super.key, this.repository});

  final ForumRepository? repository;

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  late final ForumRepository _repository;
  StreamSubscription<List<ForumPostModel>>? _subscription;

  List<ForumPostModel> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
    _subscription = _repository.watchPosts().listen(_onPosts);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onPosts(List<ForumPostModel> incoming) {
    if (!mounted) return;
    setState(() {
      _all = incoming;
      _loading = false;
    });
  }

  List<ForumPostModel> get _roots => ForumRepository.rootPosts(_all);

  Map<String, int> get _replyCounts =>
      ForumRepository.replyCountsOf(_all);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCompose() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposePostPage(repository: _repository),
      ),
    );
    if (created == true && mounted) {
      _showMessage('Publicación creada en el foro');
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForumSearchPage(repository: _repository),
      ),
    );
  }

  void _openTrends() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForumTrendsPage(repository: _repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = forumInteractionUid();
    final counts = _replyCounts;
    final roots = _roots;
    final trending = ForumRepository.sortByRelevance(roots);
    final unanswered = roots
        .where((post) => (counts[post.id] ?? 0) == 0)
        .toList(growable: false);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.neoBackground,
        appBar: AppBar(
          backgroundColor: AppColors.neoBackground,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Center(
              child: AppAvatar(
                imageUrl: AuthService.photoUrl ?? '',
                name: AuthService.displayName,
                size: 34,
                borderColor: AppColors.neoCyan.withValues(alpha: 0.6),
                borderWidth: 1.5,
              ),
            ),
          ),
          title: const Text('Foro de Dudas'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
              onPressed: _openSearch,
            ),
            IconButton(
              icon: const Icon(Icons.trending_up),
              tooltip: 'Tendencias',
              onPressed: _openTrends,
            ),
            const SizedBox(width: 6),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.neoCyan,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.neoTextMuted,
            dividerColor: AppColors.neoBorder,
            tabs: [
              Tab(text: 'Recientes'),
              Tab(text: 'Tendencias'),
              Tab(text: 'Sin responder'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.neoCyan),
                )
              : TabBarView(
                  children: [
                    ForumPostList(
                      posts: roots,
                      repository: _repository,
                      currentUserId: uid,
                      replyCounts: counts,
                      emptyState: ForumEmptyState(
                        icon: Icons.forum_outlined,
                        title: 'Todavía no hay preguntas',
                        message:
                            'Pulsa el botón de escribir para crear la primera.',
                        actionLabel: 'Crear publicación',
                        onAction: _openCompose,
                      ),
                    ),
                    ForumPostList(
                      posts: trending,
                      repository: _repository,
                      currentUserId: uid,
                      replyCounts: counts,
                      emptyState: const ForumEmptyState(
                        icon: Icons.trending_up,
                        title: 'Aún no hay tendencias',
                        message:
                            'Publica con #hashtags para que aparezcan aquí.',
                      ),
                    ),
                    ForumPostList(
                      posts: unanswered,
                      repository: _repository,
                      currentUserId: uid,
                      replyCounts: counts,
                      emptyState: const ForumEmptyState(
                        icon: Icons.check_circle_outline,
                        title: '¡Todo respondido!',
                        message:
                            'No hay preguntas pendientes de respuesta ahora mismo.',
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'forum-compose',
          backgroundColor: AppColors.neoCyan,
          foregroundColor: const Color(0xFF06232E),
          elevation: 2,
          tooltip: 'Crear publicación',
          onPressed: _openCompose,
          child: const Icon(Icons.edit_rounded, size: 22),
        ),
      ),
    );
  }
}
