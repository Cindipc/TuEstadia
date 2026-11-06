import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/models/pin.dart';
import '../../core/models/project.dart';
import '../../core/repositories/pin_repository.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/utils/project_deletion.dart';
import '../../core/widgets/app_avatar.dart';

/// Detalle de un pin (estilo Pinterest): imagen grande, autor, título y
/// descripción.
class PinDetailPage extends StatefulWidget {
  const PinDetailPage({super.key, required this.project});

  final ProjectModel project;

  @override
  State<PinDetailPage> createState() => _PinDetailPageState();
}

class _PinDetailPageState extends State<PinDetailPage> {
  late final Future<PinModel?> _pinFuture;

  @override
  void initState() {
    super.initState();
    // La descripción solo existe en el documento del pin.
    _pinFuture = PinRepository().getPin(widget.project.id);
  }

  Future<void> _delete() async {
    final confirmed = await confirmDeletion(context);
    if (!confirmed || !mounted) return;

    final ok = await deleteProjectItem(
      project: widget.project,
      pinRepository: PinRepository(),
      projectRepository: ProjectRepository(),
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo eliminar. Revisa tu sesión y las reglas.',
            ),
          ),
        );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;

    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        actions: [
          if (project.isOwnedBy(AuthService.currentUser?.uid))
            Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Eliminar publicación',
                  onPressed: _delete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PinImage(url: project.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Autor
                Row(
                  children: [
                    AppAvatar(
                      imageUrl: project.authorAvatar,
                      name: project.authorName,
                      size: 40,
                      borderColor: AppColors.neoCyan,
                      borderWidth: 1.5,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatDate(project.createdAt),
                            style: const TextStyle(
                              color: AppColors.neoTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Título
                Text(
                  project.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                // Tecnología
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neoCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    project.tech,
                    style: const TextStyle(
                      color: AppColors.neoCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Descripción (viene de Firestore)
                FutureBuilder<PinModel?>(
                  future: _pinFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neoCyan,
                          ),
                        ),
                      );
                    }

                    final description = snapshot.data?.description.trim() ?? '';
                    if (description.isEmpty) {
                      return const Text(
                        'Este pin no tiene descripción.',
                        style: TextStyle(
                          color: AppColors.neoTextMuted,
                          fontSize: 14,
                        ),
                      );
                    }
                    return Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Imagen a todo el ancho con su proporción original.
class _PinImage extends StatelessWidget {
  const _PinImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: 280,
        color: AppColors.neoSurface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 44,
          color: AppColors.neoTextMuted,
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 320,
            color: AppColors.neoSurface,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.neoCyan),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          height: 280,
          color: AppColors.neoSurface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 44,
            color: AppColors.neoTextMuted,
          ),
        ),
      ),
    );
  }
}