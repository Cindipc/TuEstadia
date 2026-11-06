import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil público de un usuario dentro del foro.
class ForumProfileModel {
  const ForumProfileModel({
    required this.uid,
    required this.displayName,
    this.username = '',
    this.email,
    this.photoUrl,
    this.bannerUrl,
    this.bio = '',
    this.postsCount = 0,
    this.repliesCount = 0,
    this.savedCount = 0,
  });

  final String uid;
  final String displayName;

  /// Nombre de usuario público sin `@`.
  final String username;

  final String? email;
  final String? photoUrl;

  /// Imagen de portada del perfil (opcional).
  final String? bannerUrl;

  final String bio;
  final int postsCount;
  final int repliesCount;
  final int savedCount;

  int get activityCount => postsCount + repliesCount;

  factory ForumProfileModel.fromMap(String uid, Map<String, dynamic> map) {
    final name = (map['displayName'] as String?)?.trim();
    final email = (map['email'] as String?)?.trim();

    return ForumProfileModel(
      uid: uid,
      displayName: name != null && name.isNotEmpty
          ? name
          : (email != null && email.contains('@'))
          ? email.split('@').first
          : 'Usuario',
      username: (map['username'] as String?)?.trim() ?? '',
      email: email,
      photoUrl: map['photoUrl'] as String?,
      bannerUrl: map['bannerUrl'] as String?,
      bio: (map['bio'] as String?) ?? '',
      postsCount: (map['postsCount'] as num?)?.toInt() ?? 0,
      repliesCount: (map['repliesCount'] as num?)?.toInt() ?? 0,
      savedCount: (map['savedCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory ForumProfileModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ForumProfileModel.fromMap(doc.id, doc.data() ?? const {});
  }

  bool matches(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return false;
    return displayName.toLowerCase().contains(term) ||
        username.toLowerCase().contains(term) ||
        (email ?? '').toLowerCase().contains(term);
  }
}
