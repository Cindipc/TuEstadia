import 'forum_post.dart';

/// Filtros de la búsqueda del foro.
class ForumSearchQuery {
  const ForumSearchQuery({
    this.text = '',
    this.authorId,
    this.since,
    this.excludeReplies = false,
    this.onlyMedia = false,
    this.onlyPoll = false,
  });

  final String text;
  final String? authorId;
  final DateTime? since;

  /// Ignora las respuestas (solo publicaciones raíz).
  final bool excludeReplies;

  /// Solo publicaciones con imágenes/vídeos/GIF.
  final bool onlyMedia;

  /// Solo publicaciones con encuesta.
  final bool onlyPoll;

  String get normalizedText => text.trim().toLowerCase();

  bool get isEmpty =>
      normalizedText.isEmpty &&
      authorId == null &&
      since == null &&
      !excludeReplies &&
      !onlyMedia &&
      !onlyPoll;

  bool matches(ForumPostModel post) {
    if (excludeReplies && !post.isRoot) return false;
    if (onlyMedia && !post.hasMedia) return false;
    if (onlyPoll && post.poll == null) return false;

    if (authorId != null && post.authorId != authorId) return false;

    final sinceDate = since;
    if (sinceDate != null && post.createdAt.isBefore(sinceDate)) return false;

    final term = normalizedText;
    if (term.isEmpty) return true;

    if (post.question.toLowerCase().contains(term)) return true;
    if (post.code.toLowerCase().contains(term)) return true;
    if (post.authorName.toLowerCase().contains(term)) return true;
    if ((post.location ?? '').toLowerCase().contains(term)) return true;
    if (post.tags.any((tag) => tag.toLowerCase().contains(term))) return true;

    // Permite buscar "#flutter" aunque el texto no lleve la almohadilla.
    final withoutHash = term.startsWith('#') ? term.substring(1) : term;
    return withoutHash.isNotEmpty &&
        post.tags.any((tag) => tag.toLowerCase() == withoutHash);
  }

  ForumSearchQuery copyWith({
    String? text,
    String? authorId,
    DateTime? since,
    bool? excludeReplies,
    bool? onlyMedia,
    bool? onlyPoll,
  }) {
    return ForumSearchQuery(
      text: text ?? this.text,
      authorId: authorId ?? this.authorId,
      since: since ?? this.since,
      excludeReplies: excludeReplies ?? this.excludeReplies,
      onlyMedia: onlyMedia ?? this.onlyMedia,
      onlyPoll: onlyPoll ?? this.onlyPoll,
    );
  }
}
