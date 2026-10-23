import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/models/project.dart';
import '../../core/repositories/project_repository.dart';
import 'widgets/project_card.dart';

/// Pantalla principal "Home - Feed".
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.repository});

  final ProjectRepository? repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String allCategory = 'Home - Feed';

  static const List<String> _categories = [
    allCategory,
    'Flutter',
    'Node.js',
    'React',
    'Firebase',
    'Python',
    'Kotlin',
    'CSS',
  ];

  final TextEditingController _searchController = TextEditingController();
  late final ProjectRepository _repository;
  late final Stream<List<ProjectModel>> _projects;

  String _selectedCategory = allCategory;
  String _searchTerm = '';
  String _sortMode = 'recientes';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProjectRepository();
    _projects = _repository.watchProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectModel> _applyFilters(List<ProjectModel> projects) {
    final term = _searchTerm.trim().toLowerCase();

    final filtered = projects.where((project) {
      final matchesCategory =
          _selectedCategory == allCategory ||
          project.tech.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          term.isEmpty ||
          project.title.toLowerCase().contains(term) ||
          project.tech.toLowerCase().contains(term) ||
          project.authorName.toLowerCase().contains(term);
      return matchesCategory && matchesSearch;
    }).toList();

    switch (_sortMode) {
      case 'populares':
        filtered.sort((a, b) => a.saved == b.saved ? 0 : (a.saved ? 1 : -1));
      case 'alfabetico':
        filtered.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return filtered;
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.neoSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const options = {
          'recientes': 'Más recientes',
          'populares': 'Más guardados',
          'alfabetico': 'Alfabético (A-Z)',
        };
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neoBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ordenar por',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              for (final entry in options.entries)
                ListTile(
                  leading: Icon(
                    _sortMode == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _sortMode == entry.key
                        ? AppColors.neoCyan
                        : AppColors.neoTextMuted,
                  ),
                  title: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, entry.key),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _sortMode = result);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildCategories(),
            Expanded(
              child: StreamBuilder<List<ProjectModel>>(
                stream: _projects,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neoCyan,
                      ),
                    );
                  }

                  final projects = _applyFilters(
                    snapshot.data ?? const <ProjectModel>[],
                  );

                  if (projects.isEmpty) {
                    return _EmptyState(onReset: _resetFilters);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.66,
                        ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () => _showMessage(project.title),
                        onToggleSave: () async {
                          final saved = await _repository.toggleSave(project);
                          if (!context.mounted) return;
                          if (!saved) {
                            _showMessage(
                              FirebaseBootstrap.isAvailable
                                  ? 'No se pudo guardar. Revisa tu sesión y las '
                                        'reglas de Firestore.'
                                  : 'Modo demo: los cambios no se guardan.',
                            );
                            return;
                          }
                          _showMessage(
                            project.saved
                                ? 'Quitado de guardados'
                                : 'Guardado en tu biblioteca',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = allCategory;
      _searchTerm = '';
      _sortMode = 'recientes';
      _searchController.clear();
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: AppColors.neoCyan,
              onChanged: (value) => setState(() => _searchTerm = value),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.neoTextMuted,
                ),
                suffixIcon: _searchTerm.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.neoTextMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchTerm = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _FilterButton(onPressed: _openFilterSheet),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isActive = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.neoCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isActive ? AppColors.neoCyan : Colors.white,
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            Icons.tune,
            size: 20,
            color: AppColors.neoCyan,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 46,
              color: AppColors.neoTextMuted,
            ),
            const SizedBox(height: 14),
            const Text(
              'No encontramos proyectos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba con otra búsqueda o cambia de categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neoTextMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neoCyan,
                side: const BorderSide(color: AppColors.neoCyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
