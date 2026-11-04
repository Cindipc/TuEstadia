import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/models/forum_trend.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/services/forum_trend_engine.dart';
import '../widgets/forum_empty_state.dart';
import '../widgets/forum_trend_card.dart';
import 'forum_search_results_page.dart';

/// Tendencias calculadas a partir de la interacción de las publicaciones.
class ForumTrendsPage extends StatefulWidget {
  const ForumTrendsPage({super.key, this.repository});

  final ForumRepository? repository;

  @override
  State<ForumTrendsPage> createState() => _ForumTrendsPageState();
}

class _ForumTrendsPageState extends State<ForumTrendsPage> {
  late final ForumRepository _repository;
  StreamSubscription<List<ForumPostModel>>? _subscription;

  List<ForumPostModel> _posts = const [];
  List<ForumTrend> _trends = const [];
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

  void _onPosts(List<ForumPostModel> posts) {
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _trends = ForumTrendEngine.compute(posts);
      _loading = false;
    });
  }

  void _refresh() {
    setState(() => _trends = ForumTrendEngine.compute(_posts));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Tendencias actualizadas')));
  }

  void _openTrend(ForumTrend trend) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForumSearchResultsPage(
          query: trend.term,
          repository: _repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Tendencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.neoCyan),
              )
            : _trends.isEmpty
            ? const ForumEmptyState(
                icon: Icons.trending_up,
                title: 'Aún no hay tendencias',
                message:
                    'Publica con #hashtags o etiquetas para que aparezcan aquí.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _trends.length + 1,
                separatorBuilder: (_, index) => index == 0
                    ? const SizedBox.shrink()
                    : const Divider(
                        color: AppColors.neoBorder,
                        height: 1,
                        indent: 40,
                      ),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader(_trends.length);
                  final trend = _trends[index - 1];
                  return ForumTrendCard(
                    rank: index,
                    trend: trend,
                    onTap: () => _openTrend(trend),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neoSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, color: AppColors.neoCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'tendencia' : 'tendencias'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ranking por interacciones (likes, respuestas, guardados y '
                  'vistas) con decaimiento por antigüedad.',
                  style: TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
