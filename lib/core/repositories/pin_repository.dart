import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../auth_service.dart';
import '../models/pin.dart';

class PinRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cloudinary
  static const String _cloudName = 'd2bwhqps';
  static const String _uploadPreset = 'pins_unsigned';

  // Ajusta si tu colección de perfiles se llama distinto.
  static const String _profilesCollection = 'users';

  CollectionReference<Map<String, dynamic>> get _pins => _db.collection('pins');

  /// Sube la imagen (bytes) a Cloudinary y devuelve su URL pública (https).
  Future<String> _uploadImage(Uint8List bytes, String fileName) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
        'No se pudo subir la imagen (${streamed.statusCode}): $body',
      );
    }
    final url = (jsonDecode(body) as Map<String, dynamic>)['secure_url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Respuesta inválida al subir la imagen');
    }
    return url;
  }

  Future<void> createPin({
    required Uint8List imageBytes,
    required String fileName,
    required String title,
    required String description,
    required String tech,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');

    final url = await _uploadImage(imageBytes, fileName);

    // 1) El pin es lo importante: si esto falla, se muestra el error.
    await _pins.add({
      'title': title.trim(),
      'description': description.trim(),
      'imageUrl': url,
      'tech': tech,
      'authorId': user.uid,
      'authorName': AuthService.displayName,
      'authorAvatar': AuthService.photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) El contador es secundario: si las reglas no lo permiten, se ignora.
    try {
      await _db.collection(_profilesCollection).doc(user.uid).set(
        {'postsCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  /// Un pin por id. Devuelve null si no existe (p. ej. un proyecto que no
  /// es un pin) o si no se pudo leer.
  Future<PinModel?> getPin(String id) async {
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
    return _pins
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((s) => s.docs.map(PinModel.fromDoc).toList());
  }

  /// Pines creados por un usuario (para el perfil).
  /// Se ordena en la app para no necesitar un índice compuesto en Firestore.
  Stream<List<PinModel>> watchMyPins(String uid) {
    return _pins.where('authorId', isEqualTo: uid).snapshots().map((s) {
      final pins = s.docs.map(PinModel.fromDoc).toList();
      // createdAt es null un instante mientras el servidor pone la fecha.
      pins.sort((a, b) {
        final da = a.createdAt ?? DateTime.now();
        final db = b.createdAt ?? DateTime.now();
        return db.compareTo(da);
      });
      return pins;
    });
  }
}