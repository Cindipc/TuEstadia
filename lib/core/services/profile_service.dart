import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_bootstrap.dart';
import '../models/forum_profile.dart';
import '../stream_utils.dart';
import 'cloudinary_service.dart';

/// Lectura y edición del perfil público del usuario.
///
/// Es instanciable para poder sustituirlo en las pruebas.
class ProfileService {
  ProfileService({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'profiles';

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Perfil del usuario (nombre, @usuario, bio y contadores).
  Stream<ForumProfileModel?> watch(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream<ForumProfileModel?>.value(null);
    }
    return withFallback<ForumProfileModel?>(
      _firestore
          .collection(collectionName)
          .doc(uid)
          .snapshots()
          .map(
            (doc) => doc.exists
                ? ForumProfileModel.fromMap(uid, doc.data() ?? const {})
                : null,
          ),
      null,
    );
  }

  /// Guarda los cambios del perfil en Auth y en Firestore.
  Future<bool> updateProfile({
    required String uid,
    required String displayName,
    required String username,
    required String bio,
    String? photoUrl,
    String? bannerUrl,
  }) async {
    final name = displayName.trim();
    final handle = _normalizeUsername(username);
    final cleanBio = bio.trim();
    final photo = photoUrl?.trim();
    final banner = (bannerUrl ?? '').trim();

    if (!FirebaseBootstrap.isAvailable) return false;

    // Auth: nombre y foto visibles en foro, tarjetas, etc.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (name.isNotEmpty && user.displayName != name) {
          await user.updateDisplayName(name);
        }
        if (photo != null && photo.isNotEmpty && user.photoURL != photo) {
          await user.updatePhotoURL(photo);
        }
      }
    } catch (_) {
      // Algunos backends no dejan cambiar el perfil al instante.
    }

    try {
      final data = <String, dynamic>{
        'displayName': name,
        'username': handle,
        'bio': cleanBio,
        // Cadena vacía = portada eliminada.
        'bannerUrl': banner,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (photo != null && photo.isNotEmpty) {
        data['photoUrl'] = photo;
      }
      await _firestore
          .collection(collectionName)
          .doc(uid)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sube una imagen (avatar o portada) a Cloudinary y devuelve la URL.
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final result = await CloudinaryService.uploadBytes(
      bytes: bytes,
      filename: filename,
    );
    return result?.url;
  }

  static String _normalizeUsername(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
  }
}
