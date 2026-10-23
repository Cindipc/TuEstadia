import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/models/chapter.dart';
import '../../core/models/course.dart';
import '../../core/repositories/library_repository.dart';

/// Pantalla "Biblioteca".
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.repository, this.onBack});

  final LibraryRepository? repository;

  /// Callback ejecutado al pulsar la flecha de retroceso.
  final VoidCallback? onBack;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final LibraryRepository _repository;
  late final Stream<List<CourseModel>> _courses;
  late final Stream<List<ChapterModel>> _chapters;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LibraryRepository();
    _courses = _repository.watchCourses();
    _chapters = _repository.watchChapters();
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
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            final navigator = Navigator.of(context);
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Mis cursos',
            color: AppColors.neoCyan,
            onPressed: () => _showMessage('Tus cursos guardados'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseCarousel(),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Chapters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _buildChapters()),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCarousel() {
    return SizedBox(
      height: 168,
      child: StreamBuilder<List<CourseModel>>(
        stream: _courses,
        builder: (context, snapshot) {
          final courses = snapshot.data ?? const <CourseModel>[];
          if (courses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neoCyan),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            physics: const BouncingScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(
                course: course,
                onTap: () => _showMessage(course.title),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChapters() {
    return StreamBuilder<List<ChapterModel>>(
      stream: _chapters,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neoCyan),
          );
        }

        final chapters = snapshot.data ?? const <ChapterModel>[];
        if (chapters.isEmpty) {
          return const Center(
            child: Text(
              'Todavía no hay capítulos disponibles.',
              style: TextStyle(color: AppColors.neoTextMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          physics: const BouncingScrollPhysics(),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return _TimelineChapter(
              chapter: chapter,
              isFirst: index == 0,
              isLast: index == chapters.length - 1,
              onContinue: () async {
                await _repository.markChapterCompleted(chapter);
                if (!context.mounted) return;
                _showMessage('Continuando: ${chapter.title}');
              },
            );
          },
        );
      },
    );
  }
}

/// Tarjeta del carrusel superior.
class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final CourseModel course;
  final VoidCallback onTap;

  static const Map<String, IconData> _icons = {
    'python': Icons.terminal,
    'flutter': Icons.flutter_dash,
    'database': Icons.storage,
    'git': Icons.commit,
    'algorithm': Icons.account_tree,
    'code': Icons.code_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        color: Color(course.colorValue),
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(course.gradientStart),
                  Color(course.gradientEnd),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _icons[course.iconKey] ?? Icons.code_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ítem de la línea de tiempo: nodo circular + línea vertical + contenido.
class _TimelineChapter extends StatelessWidget {
  const _TimelineChapter({
    required this.chapter,
    required this.isFirst,
    required this.isLast,
    required this.onContinue,
  });

  final ChapterModel chapter;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: TimelineLinePainter(
                      color: AppColors.neoBorder,
                      showTop: !isFirst,
                      showBottom: !isLast,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.neoEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 10,
                        color: AppColors.neoBackground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neoSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neoBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chapter: ${chapter.chapterNumber}',
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: chapter.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.neoBorder,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.neoEmerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(chapter.progress * 100).round()}% completado',
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.neoCyan,
                          foregroundColor: const Color(0xFF06232E),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Continuar leyendo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja la línea vertical que conecta los nodos de la línea de tiempo.
///
/// El nodo (círculo + ícono) lo dibuja el widget, de modo que el *painter*
/// solo traza los tramos de línea por encima y por debajo del nodo.
class TimelineLinePainter extends CustomPainter {
  const TimelineLinePainter({
    required this.color,
    this.nodeCenter = 28,
    this.nodeRadius = 8,
    this.showTop = true,
    this.showBottom = true,
  });

  final Color color;

  /// Distancia vertical (desde arriba) del centro del nodo.
  final double nodeCenter;
  final double nodeRadius;
  final bool showTop;
  final bool showBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (showTop) {
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, nodeCenter - nodeRadius - 3),
        linePaint,
      );
    }
    if (showBottom) {
      canvas.drawLine(
        Offset(centerX, nodeCenter + nodeRadius + 3),
        Offset(centerX, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimelineLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.nodeCenter != nodeCenter ||
        oldDelegate.nodeRadius != nodeRadius ||
        oldDelegate.showTop != showTop ||
        oldDelegate.showBottom != showBottom;
  }
}
