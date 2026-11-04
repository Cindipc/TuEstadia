import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_theme.dart';
import '../../core/models/drive_file.dart';
import 'drive_library_controller.dart';

/// Navegador de la carpeta pública de Google Drive.
class DriveLibraryView extends StatefulWidget {
  const DriveLibraryView({super.key, this.controller});

  final DriveLibraryController? controller;

  @override
  State<DriveLibraryView> createState() => _DriveLibraryViewState();
}

class _DriveLibraryViewState extends State<DriveLibraryView> {
  static const List<DriveFileCategory?> _filters = [
    null,
    DriveFileCategory.folder,
    DriveFileCategory.pdf,
    DriveFileCategory.image,
    DriveFileCategory.document,
    DriveFileCategory.spreadsheet,
    DriveFileCategory.presentation,
    DriveFileCategory.other,
  ];

  late final DriveLibraryController _controller;
  late final bool _ownsController;
  final TextEditingController _searchController = TextEditingController();
  DriveFileCategory? _category;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? DriveLibraryController();
    _controller.ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  List<DriveFile> get _visibleFiles {
    final term = _searchController.text.trim().toLowerCase();
    return _controller.files
        .where((file) {
          final matchesCategory =
              _category == null || file.category == _category;
          final matchesSearch =
              term.isEmpty || file.name.toLowerCase().contains(term);
          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 10),
            _buildFilters(),
            _buildBreadcrumb(),
            Expanded(child: _buildBody()),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar proyectos',
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.neoTextMuted,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.neoTextMuted,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _filters[index];
          final isActive = _category == category;
          return GestureDetector(
            onTap: () => setState(() => _category = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.neoCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isActive ? AppColors.neoCyan : AppColors.neoBorder,
                ),
              ),
              child: Text(
                _filterLabel(category),
                style: TextStyle(
                  color: isActive ? AppColors.onCyan : Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final path = _controller.path;
    if (path.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 18, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Carpeta anterior',
            color: AppColors.neoCyan,
            onPressed: _controller.goBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < path.length; index++) ...[
                    if (index > 0)
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.neoTextMuted,
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: index == path.length - 1
                          ? null
                          : () => _controller.goToIndex(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Text(
                          path[index].name,
                          style: TextStyle(
                            color: index == path.length - 1
                                ? Colors.white
                                : AppColors.neoTextMuted,
                            fontSize: 12.5,
                            fontWeight: index == path.length - 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final Widget content;
    switch (_controller.status) {
      case DriveLoadStatus.idle:
      case DriveLoadStatus.loading:
        content = const _SkeletonList();
      case DriveLoadStatus.error:
        content = _StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudieron cargar los proyectos',
          subtitle:
              _controller.errorMessage ??
              'Ocurrió un error inesperado. Inténtalo de nuevo.',
          onRetry: _controller.refresh,
        );
      case DriveLoadStatus.empty:
        content = const _StateMessage(
          icon: Icons.folder_open_rounded,
          title: 'Aún no hay proyectos',
          subtitle: 'Cuando agregues proyectos a Drive aparecerán aquí.',
        );
      case DriveLoadStatus.success:
        final files = _visibleFiles;
        if (files.isEmpty) {
          content = const _StateMessage(
            icon: Icons.search_off_rounded,
            title: 'Sin resultados',
            subtitle: 'Prueba con otro nombre o cambia el filtro de tipo.',
          );
        } else {
          content = ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: files.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _DriveFileCard(
                file: files[index],
                preview: _buildPreview(files[index]),
                onOpenFolder: () => _openFolder(files[index]),
                onView: () => _launchUrl(files[index].webViewLink),
                onDownload: () => _launchUrl(files[index].downloadUrl),
              );
            },
          );
        }
    }

    return RefreshIndicator(
      color: AppColors.neoCyan,
      backgroundColor: AppColors.neoSurface,
      onRefresh: _controller.refresh,
      child: content,
    );
  }

  Widget _buildPreview(DriveFile file) {
    final icon = _iconFor(file.category);
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243049), Color(0xFF16203A)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 24, color: _colorFor(file.category)),
    );

    final thumbnail = file.thumbnailLink;
    if (thumbnail == null || file.isFolder) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        thumbnail,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      ),
    );
  }

  void _openFolder(DriveFile file) {
    _searchController.clear();
    setState(() => _category = null);
    _controller.openFolder(file);
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace en el navegador.'),
            ),
          );
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace en el navegador.'),
          ),
        );
    }
  }

  static String _filterLabel(DriveFileCategory? category) {
    switch (category) {
      case null:
        return 'Todos';
      case DriveFileCategory.folder:
        return 'Carpetas';
      case DriveFileCategory.pdf:
        return 'PDF';
      case DriveFileCategory.image:
        return 'Imágenes';
      case DriveFileCategory.document:
        return 'Documentos';
      case DriveFileCategory.spreadsheet:
        return 'Hojas';
      case DriveFileCategory.presentation:
        return 'Presentaciones';
      case DriveFileCategory.other:
        return 'Otros';
    }
  }

  static IconData _iconFor(DriveFileCategory category) {
    switch (category) {
      case DriveFileCategory.folder:
        return Icons.folder_rounded;
      case DriveFileCategory.pdf:
        return Icons.picture_as_pdf_rounded;
      case DriveFileCategory.image:
        return Icons.image_rounded;
      case DriveFileCategory.document:
        return Icons.description_rounded;
      case DriveFileCategory.spreadsheet:
        return Icons.table_chart_rounded;
      case DriveFileCategory.presentation:
        return Icons.slideshow_rounded;
      case DriveFileCategory.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color _colorFor(DriveFileCategory category) {
    switch (category) {
      case DriveFileCategory.folder:
        return AppColors.neoCyan;
      case DriveFileCategory.pdf:
        return AppColors.error;
      case DriveFileCategory.image:
        return AppColors.neoEmerald;
      case DriveFileCategory.document:
        return const Color(0xFF60A5FA);
      case DriveFileCategory.spreadsheet:
        return const Color(0xFF34D399);
      case DriveFileCategory.presentation:
        return const Color(0xFFFBBF24);
      case DriveFileCategory.other:
        return AppColors.neoTextMuted;
    }
  }
}

class _DriveFileCard extends StatelessWidget {
  const _DriveFileCard({
    required this.file,
    required this.preview,
    required this.onOpenFolder,
    required this.onView,
    required this.onDownload,
  });

  final DriveFile file;
  final Widget preview;
  final VoidCallback onOpenFolder;
  final VoidCallback onView;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      file.categoryLabel,
      if (!file.isFolder && file.size != null) file.readableSize,
      if (file.modifiedTime != null) file.modifiedLabel,
    ];

    return Material(
      color: AppColors.neoSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: file.isFolder ? onOpenFolder : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neoBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 52, height: 52, child: preview),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          details.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neoTextMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (file.isFolder)
                    const Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.neoTextMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (file.isFolder)
                      TextButton.icon(
                        onPressed: onOpenFolder,
                        icon: const Icon(Icons.folder_open, size: 17),
                        label: const Text('Abrir'),
                      )
                    else ...[
                      if (file.webViewLink != null)
                        TextButton.icon(
                          onPressed: onView,
                          icon: const Icon(Icons.open_in_new, size: 17),
                          label: const Text('Ver'),
                        ),
                      if (file.downloadUrl != null)
                        TextButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: const Text('Descargar'),
                        ),
                    ],
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

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: 112,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neoSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neoBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.neoBorder,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.neoBorder,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.neoBorder,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FractionallySizedBox(
                      widthFactor: 0.35,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.neoBorder,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 72, 28, 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Icon(icon, size: 46, color: AppColors.neoTextMuted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.neoTextMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ],
    );
  }
}
