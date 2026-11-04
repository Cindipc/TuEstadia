import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/models/forum_profile.dart';
import '../../../core/models/forum_search_query.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/utils/forum_interactions.dart';
import '../widgets/forum_empty_state.dart';
import '../widgets/forum_post_list.dart';
import '../widgets/forum_search_field.dart';
import '../widgets/forum_user_tile.dart';
import 'forum_filters_sheet.dart';

/// Resultados de búsqueda con pestañas (estilo Twitter).
class ForumSearchResultsPage extends StatefulWidget {
  const ForumSearchResultsPage({
    super.key,
    required this.query,
    this.repository,
  });

  final String query;
  final ForumRepository? repository;

  @override
  State<ForumSearchResultsPage> createState() => _ForumSearchResultsPageState();
}

class _ForumSearchResultsPageState extends State<ForumSearchResultsPage> {
  late final ForumRepository _repository;
  StreamSubscription<List<ForumPostModel>>? _postsSubscription;
  StreamSubscription<List<ForumProfileModel>>? _profilesSubscription;

  List<ForumPostModel> _posts = const [];
  List<ForumProfileModel> _profiles = const [];
  ForumFilters _filters = const ForumFilters();
  late final TextEditingController _searchController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
    _searchController = TextEditingController(text: widget.query);
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
    _searchController.dispose();
    super.dispose();
  }

  ForumSearchQuery _queryFor({
    bool onlyMedia = false,
    bool onlyPoll = false,
  }) {
    return ForumSearchQuery(
      text: widget.query,
      excludeReplies: _filters.excludeReplies,
      onlyMedia: onlyMedia || _filters.onlyMedia,
      onlyPoll: onlyPoll || _filters.onlyPoll,
      since: _filters.since,
    );
  }

  void _openFilters() async {
    final result = await showForumFiltersSheet(context, _filters);
    if (result == null || !mounted) return;
    setState(() => _filters = result);
  }

  List<ForumPostModel> _results({
    bool relevance = false,
    bool onlyMedia = false,
    bool onlyPoll = false,
  }) {
    final results = ForumRepository.searchPosts(
      _posts,
      _queryFor(onlyMedia: onlyMedia, onlyPoll: onlyPoll),
    );
    return relevance ? ForumRepository.sortByRelevance(results) : results;
  }

  @override
  Widget build(BuildContext context) {
    final counts = ForumRepository.replyCountsOf(_posts);
    final uid = forumInteractionUid();
    final people = _profiles
        .where((profile) => profile.matches(widget.query))
        .toList(growable: false);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.neoBackground,
        appBar: AppBar(
          backgroundColor: AppColors.neoBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ForumSearchField(
              controller: _searchController,
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => ForumSearchResultsPage(
                      query: value.trim(),
                      repository: _repository,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filtros',
              onPressed: _openFilters,
            ),
            const SizedBox(width: 4),
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
              Tab(text: 'Destacados'),
              Tab(text: 'Recientes'),
              Tab(text: 'Personas'),
              Tab(text: 'Multimedia'),
              Tab(text: 'Listas'),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.neoCyan),
              )
            : TabBarView(
                children: [
                  _buildPosts(
                    _results(relevance: true),
                    counts,
                    uid,
                    'Sin resultados destacados',
                  ),
                  _buildPosts(
                    _results(),
                    counts,
                    uid,
                    'Sin resultados recientes',
                  ),
                  _buildPeople(people),
                  _buildPosts(
                    _results(onlyMedia: true),
                    counts,
                    uid,
                    'No hay multimedia para esta búsqueda',
                  ),
                  _buildPosts(
                    _results(onlyPoll: true),
                    counts,
                    uid,
                    'No hay encuestas para esta búsqueda',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPosts(
    List<ForumPostModel> posts,
    Map<String, int> counts,
    String? uid,
    String emptyTitle,
  ) {
    return ForumPostList(
      posts: posts,
      repository: _repository,
      currentUserId: uid,
      replyCounts: counts,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      emptyState: ForumEmptyState(
        icon: Icons.search_off,
        title: emptyTitle,
        message: 'Prueba con otras palabras o revisa los filtros.',
      ),
    );
  }

  Widget _buildPeople(List<ForumProfileModel> people) {
    if (people.isEmpty) {
      return const ForumEmptyState(
        icon: Icons.person_search_outlined,
        title: 'No se encontraron personas',
        message: 'Prueba con otro nombre o correo.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: people.length,
      separatorBuilder: (_, _) =>
          const Divider(color: AppColors.neoBorder, height: 1, indent: 72),
      itemBuilder: (context, index) {
        final profile = people[index];
        return ForumUserTile(
          profile: profile,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ForumSearchResultsPage(
                query: profile.displayName,
                repository: _repository,
              ),
            ),
          ),
        );
      },
    );
  }
}
