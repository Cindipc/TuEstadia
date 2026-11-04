import 'dart:math' as math;

import '../models/forum_post.dart';
import '../models/forum_trend.dart';

/// Motor de tendencias del foro (100 % cliente, sin Cloud Functions).
///
/// Cada publicación aporta a sus temas (hashtags, etiquetas y autor) una
/// puntuación de interacción ponderada que decae con el tiempo:
///
/// ```text
/// engagement = 1.0·likes + 2.5·respuestas + 1.5·guardados + 0.15·vistas
/// recencia   = 0.5 ^ (edad_horas / 18)
/// score      = Σ engagement · recencia          (normalizado a 0..100)
/// ```
class ForumTrendEngine {
  ForumTrendEngine._();

  static const double likeWeight = 1.0;
  static const double replyWeight = 2.5;
  static const double saveWeight = 1.5;
  static const double viewWeight = 0.15;

  /// Vida media del decaimiento: cada 18 h una interacción vale la mitad.
  static const double halfLifeHours = 18;

  static const double authorWeight = 0.6;

  static const Duration defaultWindow = Duration(days: 7);

  static final RegExp _hashtagPattern = RegExp(
    r'#([\wáéíóúñü]+)',
    caseSensitive: false,
  );

  /// Calcula las tendencias a partir de [posts].
  static List<ForumTrend> compute(
    List<ForumPostModel> posts, {
    DateTime? now,
    Duration window = defaultWindow,
    int limit = 20,
  }) {
    final reference = now ?? DateTime.now();
    final cutoff = reference.subtract(window);
    final buckets = <String, _TrendBucket>{};

    for (final post in posts) {
      if (post.createdAt.isBefore(cutoff)) continue;

      final weighted =
          engagementOf(post) * recencyFactor(post.createdAt, reference);
      if (weighted <= 0) continue;

      final hashtags = extractHashtags(post.question).toSet();
      final tags = post.tags
          .map((tag) => tag.replaceAll('#', '').trim().toLowerCase())
          .where((tag) => tag.isNotEmpty);

      final topics = <String, ForumTrendKind>{};
      for (final hashtag in hashtags) {
        topics[hashtag] = ForumTrendKind.hashtag;
      }
      for (final tag in tags) {
        topics.putIfAbsent(tag, () => ForumTrendKind.technology);
      }

      for (final entry in topics.entries) {
        buckets
            .putIfAbsent(
              'topic:${entry.key}',
              () => _TrendBucket(entry.key, entry.value),
            )
            .add(post, weighted);
      }

      final author = post.authorName.trim();
      if (author.isNotEmpty) {
        buckets
            .putIfAbsent(
              'author:${author.toLowerCase()}',
              () => _TrendBucket(author, ForumTrendKind.author),
            )
            .add(post, weighted * authorWeight);
      }
    }

    if (buckets.isEmpty) return const [];

    final drafts = buckets.values
        .map(
          (bucket) => ForumTrend(
            term: bucket.term,
            kind: bucket.kind,
            postCount: bucket.postCount,
            engagement: bucket.engagement.round(),
            score: bucket.score,
            lastActivity: bucket.lastActivity ?? reference,
          ),
        )
        .toList();

    final maxScore = drafts
        .map((trend) => trend.score)
        .reduce(math.max)
        .clamp(1e-9, double.infinity);

    final normalized = drafts
        .map(
          (trend) => trend.copyWith(score: (trend.score / maxScore) * 100),
        )
        .toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return b.lastActivity.compareTo(a.lastActivity);
      });

    return normalized.take(limit).toList(growable: false);
  }

  /// Interacción ponderada de una publicación.
  static double engagementOf(ForumPostModel post) {
    return likeWeight * post.likes +
        replyWeight * post.replies +
        saveWeight * post.savedBy.length +
        viewWeight * post.views.length;
  }

  /// Factor de recencia entre 0 y 1 (1 = recién publicado).
  static double recencyFactor(DateTime createdAt, DateTime now) {
    final hours = now.difference(createdAt).inMinutes / 60.0;
    final age = hours < 0 ? 0.0 : hours;
    return math.pow(0.5, age / halfLifeHours).toDouble();
  }

  /// Extrae hashtags en minúsculas y sin `#`.
  static List<String> extractHashtags(String text) {
    return _hashtagPattern
        .allMatches(text)
        .map((match) => match.group(1)!.toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

class _TrendBucket {
  _TrendBucket(this.term, this.kind);

  final String term;
  final ForumTrendKind kind;

  double score = 0;
  double engagement = 0;
  int postCount = 0;
  DateTime? lastActivity;

  void add(ForumPostModel post, double weighted) {
    score += weighted;
    engagement += ForumTrendEngine.engagementOf(post);
    postCount += 1;
    final previous = lastActivity;
    if (previous == null || post.createdAt.isAfter(previous)) {
      lastActivity = post.createdAt;
    }
  }
}
