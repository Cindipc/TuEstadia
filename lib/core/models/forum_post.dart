import 'package:cloud_firestore/cloud_firestore.dart';

import 'forum_media.dart';
import 'forum_poll.dart';

/// Publicación del foro de dudas.
///
/// Las respuestas viven en la misma colección `posts` y apuntan a su
/// publicación padre con [parentPostId] (mismo patrón que `fwitter_reborn`).
class ForumPostModel {
  const ForumPostModel({
    required this.id,
    this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.question,
    required this.code,
    required this.likes,
    this.likedBy = const [],
    required this.replies,
    required this.saved,
    this.savedBy = const [],
    this.views = const [],
    this.media = const [],
    this.tags = const [],
    this.location,
    this.poll,
    this.parentPostId,
    required this.createdAt,
  });

  final String id;

  /// uid del autor (vínculo con `profiles`).
  final String? authorId;

  final String authorName;
  final String authorAvatar;
  final String question;

  /// Fragmento de código opcional (se renderiza con syntax highlighting).
  final String code;

  /// Contador de likes (desnormalizado para no leer [likedBy] siempre).
  final int likes;

  /// uids de quienes dieron like.
  final List<String> likedBy;

  final int replies;
  final bool saved;

  /// uids de quienes guardaron la publicación.
  final List<String> savedBy;

  /// uids de quienes vieron el hilo.
  final List<String> views;

  /// Imágenes, vídeos y GIFs adjuntos (Cloudinary).
  final List<ForumMediaModel> media;

  /// Etiquetas/temas del post (sin `#`).
  final List<String> tags;

  /// Ubicación legible (opcional).
  final String? location;

  /// Encuesta adjunta (opcional).
  final ForumPollModel? poll;

  /// `null` en publicaciones raíz; id del padre en las respuestas.
  final String? parentPostId;

  final DateTime createdAt;

  bool get isRoot => parentPostId == null;

  bool get hasMedia => media.isNotEmpty;

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);

  bool isSavedBy(String? uid) => uid != null && savedBy.contains(uid);

  bool isOwnedBy(String? uid) => uid != null && authorId == uid;

  factory ForumPostModel.fromMap(String id, Map<String, dynamic> map) {
    final rawParent = map['parentPostId'];
    final parentPostId = rawParent is String && rawParent.isNotEmpty
        ? rawParent
        : null;

    final likedBy = _readStringList(map['likedBy']);
    final rawLikes = (map['likes'] as num?)?.toInt();

    return ForumPostModel(
      id: id,
      authorId: (map['authorId'] as String?)?.trim().isEmpty ?? true
          ? null
          : map['authorId'] as String?,
      authorName: (map['authorName'] as String?) ?? 'Anónimo',
      authorAvatar: (map['authorAvatar'] as String?) ?? '',
      question: (map['question'] as String?) ?? '',
      code: (map['code'] as String?) ?? '',
      // Compatibilidad: documentos antiguos sin contador usan el largo del array.
      likes: rawLikes ?? likedBy.length,
      likedBy: likedBy,
      replies: (map['replies'] as num?)?.toInt() ?? 0,
      saved: (map['saved'] as bool?) ?? false,
      savedBy: _readStringList(map['savedBy']),
      views: _readStringList(map['views']),
      media: _readMedia(map['media']),
      tags: _readStringList(map['tags']),
      location: (map['location'] as String?)?.trim().isEmpty ?? true
          ? null
          : map['location'] as String?,
      poll: map['poll'] is Map
          ? ForumPollModel.fromMap(
              Map<String, dynamic>.from(map['poll'] as Map),
            )
          : null,
      parentPostId: parentPostId,
      createdAt: _readDate(map['createdAt']),
    );
  }

  factory ForumPostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ForumPostModel.fromMap(doc.id, doc.data() ?? const {});
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'question': question,
      'code': code,
      'likes': likes,
      'likedBy': likedBy,
      'replies': replies,
      'saved': saved,
      'savedBy': savedBy,
      'views': views,
      'media': media.map((item) => item.toMap()).toList(growable: false),
      'tags': tags,
      'location': location,
      'poll': poll?.toMap(),
      'parentPostId': parentPostId,
      'createdAt': createdAt,
    };
  }

  ForumPostModel copyWith({
    int? likes,
    List<String>? likedBy,
    int? replies,
    bool? saved,
    List<String>? savedBy,
    List<String>? views,
    ForumPollModel? poll,
  }) {
    return ForumPostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      question: question,
      code: code,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      replies: replies ?? this.replies,
      saved: saved ?? this.saved,
      savedBy: savedBy ?? this.savedBy,
      views: views ?? this.views,
      media: media,
      tags: tags,
      location: location,
      poll: poll ?? this.poll,
      parentPostId: parentPostId,
      createdAt: createdAt,
    );
  }

  static List<ForumMediaModel> _readMedia(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(ForumMediaModel.tryFrom)
        .whereType<ForumMediaModel>()
        .toList(growable: false);
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return const [];
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
