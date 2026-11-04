import 'package:flutter/foundation.dart';

import '../../core/config/drive_config.dart';
import '../../core/models/drive_file.dart';
import '../../core/services/drive_service.dart';

enum DriveLoadStatus { idle, loading, success, empty, error }

class DriveLocation {
  const DriveLocation({required this.id, required this.name});

  final String id;
  final String name;
}

class _CacheEntry {
  const _CacheEntry({required this.files, required this.loadedAt});

  final List<DriveFile> files;
  final DateTime loadedAt;
}

/// Estado y caché en memoria del navegador de archivos de Drive.
class DriveLibraryController extends ChangeNotifier {
  DriveLibraryController({
    DriveService? service,
    String? rootFolderId,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ?? DriveService(),
       _ownsService = service == null,
       _rootFolderId = rootFolderId ?? DriveConfig.rootFolderId {
    _path.add(DriveLocation(id: _rootFolderId, name: 'Inicio'));
  }

  final DriveService _service;
  final bool _ownsService;
  final String _rootFolderId;
  final Duration cacheTtl;
  final Map<String, _CacheEntry> _cache = {};
  final List<DriveLocation> _path = [];

  List<DriveFile> _files = const [];
  DriveLoadStatus _status = DriveLoadStatus.idle;
  String? _errorMessage;
  int _requestId = 0;
  bool _disposed = false;

  List<DriveFile> get files => _files;
  DriveLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<DriveLocation> get path => List.unmodifiable(_path);
  bool get canGoBack => _path.length > 1;

  void ensureLoaded() {
    if (_status == DriveLoadStatus.idle) {
      loadCurrent();
    }
  }

  Future<void> loadCurrent({bool forceRefresh = false}) async {
    final folderId = _path.isEmpty ? _rootFolderId : _path.last.id;
    await _load(folderId, forceRefresh: forceRefresh);
  }

  Future<void> refresh() => loadCurrent(forceRefresh: true);

  Future<void> openFolder(DriveFile folder) async {
    if (!folder.isFolder || folder.id.isEmpty) return;
    _path.add(DriveLocation(id: folder.id, name: folder.name));
    await loadCurrent();
  }

  Future<void> goBack() async {
    if (!canGoBack) return;
    _path.removeLast();
    await loadCurrent();
  }

  Future<void> goToIndex(int index) async {
    if (index < 0 || index >= _path.length - 1) return;
    _path.removeRange(index + 1, _path.length);
    await loadCurrent();
  }

  Future<void> _load(String folderId, {required bool forceRefresh}) async {
    final requestId = ++_requestId;

    if (!forceRefresh) {
      final cached = _cache[folderId];
      if (cached != null &&
          DateTime.now().difference(cached.loadedAt) < cacheTtl) {
        _files = cached.files;
        _status = cached.files.isEmpty
            ? DriveLoadStatus.empty
            : DriveLoadStatus.success;
        _errorMessage = null;
        _safeNotify();
        return;
      }
    }

    _status = DriveLoadStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final files = await _service.listFiles(folderId: folderId);
      if (_disposed || requestId != _requestId) return;

      _cache[folderId] = _CacheEntry(files: files, loadedAt: DateTime.now());
      _files = files;
      _status = files.isEmpty ? DriveLoadStatus.empty : DriveLoadStatus.success;
    } on DriveException catch (error) {
      if (_disposed || requestId != _requestId) return;
      _files = const [];
      _errorMessage = error.message;
      _status = DriveLoadStatus.error;
    } catch (_) {
      if (_disposed || requestId != _requestId) return;
      _files = const [];
      _errorMessage =
          'Ocurrió un error inesperado al cargar Google Drive. Inténtalo de '
          'nuevo.';
      _status = DriveLoadStatus.error;
    }

    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsService) _service.dispose();
    super.dispose();
  }
}
