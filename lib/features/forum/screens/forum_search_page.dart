import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/models/forum_profile.dart';
import '../../../core/models/forum_search_query.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/services/forum_trend_engine.dart';
import '../../../core/widgets/app_avatar.dart';
import '../widgets/forum_empty_state.dart';
import '../widgets/forum_search_field.dart';
import '../widgets/forum_trend_card.dart';
import '../widgets/forum_user_tile.dart';
import 'forum_search_results_page.dart';
import 'post_detail_page.dart';

/// Búsqueda con sugerencias en vivo (personas, publicaciones y tendencias).
class ForumSearchPage extends StatefulWidget {
  const ForumSearchPage({super.key, this.repository});

  final ForumRepository? repository;

  @override
  State<ForumSearchPage> createState() => _ForumSearchPageState();
}

class _ForumSearchPageState extends State<ForumSearchPage> {
  late final ForumRepository _repository;
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<List<ForumPostModel>>? _postsSubscription;
  StreamSubscription<List<ForumProfileModel>>? _profilesSubscription;

  List<ForumPostModel> _posts = const [];
  List<ForumProfileModel> _profiles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
    _postsSubscription = _repository.watchPosts().listen((posts) {
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    });
    _profilesSubscription = _repository.watchProfiles().listen((profiles) {
      if (!mounted) return;
      setState(() => _profiles = profiles);
    });
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _profilesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  void _openResults(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ForumSearchResultsPage(
          query: value,
          repository: _repository,
        ),
      ),
    );
  }

  void _openThread(ForumPostModel post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailPage(post: post, repository: _repository),
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ForumSearchField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onSubmitted: _openResults,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.neoCyan),
              )
            : _query.isEmpty
            ? _buildDiscover()
            : _buildSuggestions(),
      ),
    );
  }

  Widget _buildDiscover() {
    final trends = ForumTrendEngine.compute(_posts).take(5).toList();
    final people = _profiles.take(5).toList();

    if (trends.isEmpty && people.isEmpty) {
      return const ForumEmptyState(
        icon: Icons.search,
        title: 'Busca en el foro',
        message: 'Prueba con personas, temas o #hashtags.',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (trends.isNotEmpty) ...[
          const _SectionHeader(title: 'Tendencias'),
          for (var index = 0; index < trends.length; index++)
            ForumTrendCard(
              rank: index + 1,
              trend: trends[index],
              onTap: () => _openResults(trends[index].term),
            ),
        ],
        if (people.isNotEmpty) ...[
          const _SectionHeader(title: 'Personas'),
          for (final profile in people)
            ForumUserTile(
              profile: profile,
              onTap: () => _openResults(profile.displayName),
            ),
        ],
      ],
    );
  }

  Widget _buildSuggestions() {
    final query = _query;
    final matchingPosts = ForumRepository.searchPosts(
      _posts,
      ForumSearchQuery(text: query),
    );
    final people = _profiles
        .where((profile) => profile.matches(query))
        .take(3)
        .toList(growable: false);
    final posts = matchingPosts.take(5).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ListTile(
          leading: const Icon(Icons.search, color: AppColors.neoCyan),
          title: Text(
            'Buscar "$query"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward,
            size: 17,
            color: AppColors.neoTextMuted,
          ),
          onTap: () => _openResults(query),
        ),
        if (people.isNotEmpty) ...[
          const _SectionHeader(title: 'Personas'),
          for (final profile in people)
            ForumUserTile(
              profile: profile,
              onTap: () => _openResults(profile.displayName),
            ),
        ],
        if (posts.isNotEmpty) ...[
          const _SectionHeader(title: 'Publicaciones'),
          for (final post in posts)
            _SuggestionPostTile(post: post, onTap: () => _openThread(post)),
        ],
        if (posts.isEmpty && people.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ForumEmptyState(
              icon: Icons.search_off,
              title: 'Sin resultados',
              message: 'No encontramos nada para "$query".',
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.neoTextMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SuggestionPostTile extends StatelessWidget {
  const _SuggestionPostTile({required this.post, required this.onTap});

  final ForumPostModel post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: post.authorAvatar,
                name: post.authorName,
                size: 34,
                borderColor: AppColors.neoCyan.withValues(alpha: 0.4),
                borderWidth: 1.2,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${post.authorName} · ${post.likes} likes · '
                      '${post.replies} respuestas',
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
