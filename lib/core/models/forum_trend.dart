/// Categoría de una tendencia del foro.
enum ForumTrendKind { hashtag, technology, author }

/// Tendencia calculada a partir de las publicaciones.
class ForumTrend {
  const ForumTrend({
    required this.term,
    required this.kind,
    required this.postCount,
    required this.engagement,
    required this.score,
    required this.lastActivity,
  });

  /// Término sin `#` ni `@`.
  final String term;

  final ForumTrendKind kind;
  final int postCount;

  /// Suma de interacciones ponderadas.
  final int engagement;

  /// Puntuación normalizada de 0 a 100.
  final double score;

  final DateTime lastActivity;

  String get displayTerm => switch (kind) {
    ForumTrendKind.hashtag => '#$term',
    ForumTrendKind.author => '@$term',
    ForumTrendKind.technology => term,
  };

  ForumTrend copyWith({double? score, int? postCount, int? engagement}) {
    return ForumTrend(
      term: term,
      kind: kind,
      postCount: postCount ?? this.postCount,
      engagement: engagement ?? this.engagement,
      score: score ?? this.score,
      lastActivity: lastActivity,
    );
  }
}
