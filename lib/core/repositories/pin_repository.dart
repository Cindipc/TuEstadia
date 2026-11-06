import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth_service.dart';
import '../firebase_bootstrap.dart';
import '../models/pin.dart';
import '../services/cloudinary_service.dart';
import '../stream_utils.dart';

class PinRepository {
  PinRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'pins';
  static const String profilesCollection = 'profiles';

  final FirebaseFirestore? _injected;

  /// Acceso perezoso: en modo demo nunca se instancia Firestore.
  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pins =>
      _db.collection(collectionName);

  /// Sube la imagen a Cloudinary y la guarda como pin del usuario actual.
  Future<void> createPin({
    required Uint8List imageBytes,
    required String fileName,
    required String title,
    required String description,
    required String tech,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final upload = await CloudinaryService.uploadBytes(
      bytes: imageBytes,
      filename: fileName,
    );
    if (upload == null) {
      throw Exception('No se pudo subir la imagen a Cloudinary');
    }

    // 1) El pin es lo importante: si esto falla, se muestra el error.
    await _pins.add({
      'title': title.trim(),
      'description': description.trim(),
      'imageUrl': upload.url,
      'tech': tech,
      'authorId': user.uid,
      'authorName': AuthService.displayName,
      'authorAvatar': AuthService.photoUrl ?? '',
      'savedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) El contador es secundario: si las reglas no lo permiten, se ignora.
    try {
      await _db.collection(profilesCollection).doc(user.uid).set({
        'pinsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Un pin por id. Devuelve null si no existe (p. ej. un proyecto que no
  /// es un pin) o si no se pudo leer.
  Future<PinModel?> getPin(String id) async {
    if (!FirebaseBootstrap.isAvailable) return null;
    try {
      final doc = await _pins.doc(id).get();
      if (!doc.exists) return null;
      return PinModel.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  /// Feed general: los pines más recientes.
  Stream<List<PinModel>> watchFeed() {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <PinModel>[]);
    }
    return withFallback(
      _pins
          .orderBy('createdAt', descending: true)
          .limit(60)
          .snapshots()
          .map((s) => s.docs.map(PinModel.fromDoc).toList(growable: false)),
      const <PinModel>[],
    );
  }

  /// Pines creados por un usuario (para el perfil).
  /// Se ordena en la app para no necesitar un índice compuesto en Firestore.
  Stream<List<PinModel>> watchMyPins(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <PinModel>[]);
    }
    return withFallback(
      _pins.where('authorId', isEqualTo: uid).snapshots().map((s) {
        final pins = s.docs.map(PinModel.fromDoc).toList();
        _sortByDate(pins);
        return pins;
      }),
      const <PinModel>[],
    );
  }

  /// Pines guardados por un usuario (para "Guardados" del perfil).
  Stream<List<PinModel>> watchSavedPins(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <PinModel>[]);
    }
    return withFallback(
      _pins.where('savedBy', arrayContains: uid).snapshots().map((s) {
        final pins = s.docs.map(PinModel.fromDoc).toList();
        _sortByDate(pins);
        return pins;
      }),
      const <PinModel>[],
    );
  }

  Future<bool> toggleSave({
    required String pinId,
    required String uid,
    required bool currentlySaved,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _pins.doc(pinId).update({
        'savedBy': currentlySaved
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _sortByDate(List<PinModel> pins) {
    pins.sort((a, b) {
      final da = a.createdAt ?? DateTime.now();
      final db = b.createdAt ?? DateTime.now();
      return db.compareTo(da);
    });
  }
}
