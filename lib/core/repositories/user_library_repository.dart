import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_bootstrap.dart';
import '../models/drive_file.dart';
import '../models/library_item.dart';
import '../stream_utils.dart';

/// Biblioteca personal: archivos de Drive asignados a cada usuario.
class UserLibraryRepository {
  UserLibraryRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const String collectionName = 'libraryItems';

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// id determinista: un elemento por usuario y archivo.
  static String docIdFor(String uid, String fileId) => '${uid}_$fileId';

  /// Elementos de la biblioteca del usuario, del más reciente al más antiguo.
  Stream<List<LibraryItemModel>> watchMyLibrary(String uid) {
    if (!FirebaseBootstrap.isAvailable) {
      return Stream.value(const <LibraryItemModel>[]);
    }
    return withFallback(
      _collection
          .where('ownerId', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
            final items = snapshot.docs
                .map(LibraryItemModel.fromDoc)
                .toList();
            items.sort((a, b) {
              final da = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final db = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });
            return items;
          }),
      const <LibraryItemModel>[],
    );
  }

  /// IDs de archivo ya asignados (para pintar el bookmark en la biblioteca).
  Stream<Set<String>> watchSavedFileIds(String uid) {
    return watchMyLibrary(uid).map(
      (items) => items.map((item) => item.fileId).toSet(),
    );
  }

  /// Añade o quita un archivo de la biblioteca del usuario.
  Future<bool> toggleItem({
    required String uid,
    required DriveFile file,
  }) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    final docId = docIdFor(uid, file.id);
    try {
      final ref = _collection.doc(docId);
      final snapshot = await ref.get();
      if (snapshot.exists) {
        await ref.delete();
      } else {
        final item = LibraryItemModel.fromDriveFile(
          id: docId,
          ownerId: uid,
          file: file,
        );
        await ref.set(item.toMap());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeItem(String docId) async {
    if (!FirebaseBootstrap.isAvailable) return false;
    try {
      await _collection.doc(docId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
