import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Resultado de la hoja de filtros de búsqueda.
class ForumFilters {
  const ForumFilters({
    this.excludeReplies = false,
    this.onlyMedia = false,
    this.onlyPoll = false,
    this.since,
  });

  final bool excludeReplies;
  final bool onlyMedia;
  final bool onlyPoll;
  final DateTime? since;

  ForumFilters copyWith({
    bool? excludeReplies,
    bool? onlyMedia,
    bool? onlyPoll,
    DateTime? since,
    bool clearSince = false,
  }) {
    return ForumFilters(
      excludeReplies: excludeReplies ?? this.excludeReplies,
      onlyMedia: onlyMedia ?? this.onlyMedia,
      onlyPoll: onlyPoll ?? this.onlyPoll,
      since: clearSince ? null : (since ?? this.since),
    );
  }
}

Future<ForumFilters?> showForumFiltersSheet(
  BuildContext context,
  ForumFilters initial,
) {
  return showModalBottomSheet<ForumFilters>(
    context: context,
    backgroundColor: AppColors.neoSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _ForumFiltersSheet(initial: initial),
  );
}

class _ForumFiltersSheet extends StatefulWidget {
  const _ForumFiltersSheet({required this.initial});

  final ForumFilters initial;

  @override
  State<_ForumFiltersSheet> createState() => _ForumFiltersSheetState();
}

class _ForumFiltersSheetState extends State<_ForumFiltersSheet> {
  static const List<({String label, Duration? window})> _ranges = [
    (label: 'Cualquiera', window: null),
    (label: 'Últimas 24 h', window: Duration(days: 1)),
    (label: 'Última semana', window: Duration(days: 7)),
    (label: 'Último mes', window: Duration(days: 30)),
  ];

  late ForumFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  int get _rangeIndex {
    final since = _filters.since;
    if (since == null) return 0;
    final age = DateTime.now().difference(since);
    for (var index = 1; index < _ranges.length; index++) {
      final window = _ranges[index].window!;
      if (age.inHours <= window.inHours + 1) return index;
    }
    return _ranges.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neoBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _filters = const ForumFilters()),
                  child: const Text(
                    'Restablecer',
                    style: TextStyle(color: AppColors.neoCyan, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Excluir respuestas',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: _filters.excludeReplies,
              activeThumbColor: AppColors.neoCyan,
              onChanged: (value) => setState(
                () => _filters = _filters.copyWith(excludeReplies: value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Solo con imágenes o vídeos',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: _filters.onlyMedia,
              activeThumbColor: AppColors.neoCyan,
              onChanged: (value) => setState(
                () => _filters = _filters.copyWith(onlyMedia: value),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Solo con encuesta',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              value: _filters.onlyPoll,
              activeThumbColor: AppColors.neoCyan,
              onChanged: (value) => setState(
                () => _filters = _filters.copyWith(onlyPoll: value),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Fecha de publicación',
              style: TextStyle(
                color: AppColors.neoTextMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _ranges.length; index++)
                  ChoiceChip(
                    label: Text(_ranges[index].label),
                    selected: _rangeIndex == index,
                    onSelected: (_) {
                      final window = _ranges[index].window;
                      setState(() {
                        _filters = window == null
                            ? _filters.copyWith(clearSince: true)
                            : _filters.copyWith(
                                since: DateTime.now().subtract(window),
                              );
                      });
                    },
                    selectedColor: AppColors.neoCyan.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _rangeIndex == index
                          ? AppColors.neoCyan
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: AppColors.neoBorder),
                    backgroundColor: AppColors.neoSurfaceAlt,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_filters),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neoCyan,
                foregroundColor: const Color(0xFF06232E),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Aplicar filtros',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
