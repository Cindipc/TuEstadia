import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../core/firebase_bootstrap.dart';
import '../../../core/models/forum_media.dart';
import '../../../core/models/forum_poll.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/repositories/forum_repository.dart';
import '../../../core/services/forum_trend_engine.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/widgets/app_avatar.dart';
import '../widgets/forum_char_counter.dart';
import '../widgets/forum_composer_bar.dart';
import '../widgets/forum_media_preview.dart';

/// Compositor de publicaciones estilo Twitter.
///
/// Texto + adjuntos (imágenes, vídeos, GIF), encuesta, ubicación y bloque de
/// código, con las herramientas en la barra inferior.
class ComposePostPage extends StatefulWidget {
  const ComposePostPage({super.key, this.parentPost, this.repository});

  /// Si no es nulo, lo que se publique será una respuesta a este post.
  final ForumPostModel? parentPost;
  final ForumRepository? repository;

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  static const int maxChars = 280;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final ForumRepository _repository;

  final List<ForumMediaModel> _media = [];
  final List<TextEditingController> _pollControllers = [];

  bool _showCode = false;
  bool _pollEnabled = false;
  bool _uploading = false;
  bool _sending = false;
  String? _location;

  bool get _isReply => widget.parentPost != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ForumRepository();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _codeController.dispose();
    for (final controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Adjuntos ─────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    await _pick(() => _picker.pickMultipleMedia());
  }

  Future<void> _takePhoto() async {
    await _pick(
      () => _picker
          .pickImage(source: ImageSource.camera, imageQuality: 90)
          .then((file) => file == null ? <XFile>[] : [file]),
    );
  }

  Future<void> _pickGif() async {
    await _pick(
      () => _picker
          .pickMedia()
          .then((file) => file == null ? <XFile>[] : [file]),
    );
  }

  Future<void> _pick(Future<List<XFile>> Function() picker) async {
    if (_uploading) return;

    final remaining = MediaUploadService.maxItems - _media.length;
    if (remaining <= 0) {
      _showMessage('Puedes adjuntar hasta 4 archivos.');
      return;
    }

    List<XFile> files;
    try {
      files = await picker();
    } catch (error) {
      _showMessage('No se pudo abrir el selector de archivos: $error');
      return;
    }
    if (files.isEmpty) return;

    setState(() => _uploading = true);
    final outcomes = await MediaUploadService.uploadAll(files);
    if (!mounted) return;

    final uploaded = outcomes
        .where((outcome) => outcome.isSuccess)
        .map((outcome) => outcome.media!)
        .toList();
    final failures = outcomes
        .where((outcome) => !outcome.isSuccess)
        .map((outcome) => outcome.error)
        .whereType<String>()
        .toList();

    setState(() {
      _uploading = false;
      _media.addAll(uploaded.take(remaining));
    });

    if (failures.isNotEmpty) {
      _showMessage(failures.first);
    }
  }

  void _removeMedia(int index) {
    setState(() => _media.removeAt(index));
  }

  // ── Encuesta ─────────────────────────────────────────────────────────────

  void _togglePoll() {
    setState(() {
      _pollEnabled = !_pollEnabled;
      if (_pollEnabled) {
        while (_pollControllers.length < 2) {
          _pollControllers.add(TextEditingController());
        }
      }
    });
  }

  void _addPollOption() {
    if (_pollControllers.length >= 4) return;
    setState(() => _pollControllers.add(TextEditingController()));
  }

  void _removePollOption(int index) {
    if (_pollControllers.length <= 2) return;
    setState(() {
      _pollControllers.removeAt(index).dispose();
    });
  }

  ForumPollModel? _buildPoll() {
    if (!_pollEnabled) return null;
    final texts = _pollControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList(growable: false);
    if (texts.length < 2) return null;

    return ForumPollModel(
      options: [
        for (var index = 0; index < texts.length; index++)
          ForumPollOption(id: 'option-$index', text: texts[index]),
      ],
    );
  }

  // ── Ubicación ────────────────────────────────────────────────────────────

  Future<void> _editLocation() async {
    if (_location != null) {
      setState(() => _location = null);
      return;
    }

    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.neoSurface,
          title: const Text(
            'Añadir ubicación',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Ciudad o lugar'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || value == null || value.isEmpty) return;
    setState(() => _location = value);
  }

  // ── Publicar ─────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (_sending) return;

    final question = _questionController.text.trim();
    if (question.isEmpty) {
      _showMessage('Escribe tu pregunta antes de publicar.');
      return;
    }
    if (question.length > maxChars) {
      _showMessage('El texto supera los $maxChars caracteres.');
      return;
    }
    if (_uploading) {
      _showMessage('Espera a que terminen las subidas.');
      return;
    }

    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      _showMessage('Inicia sesión para publicar en el foro.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    final created = await _repository.createPost(
      question: question,
      code: _showCode ? _codeController.text.trim() : '',
      authorId: uid,
      authorName: AuthService.displayName,
      authorAvatar: AuthService.photoUrl ?? '',
      parentPostId: widget.parentPost?.id,
      media: List.unmodifiable(_media),
      tags: ForumTrendEngine.extractHashtags(question),
      location: _location,
      poll: _buildPoll(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (!created) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo publicar: revisa tu sesión y las reglas de Firestore.'
            : 'Modo demo: las publicaciones no se guardan.',
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
        ),
        title: Text(_isReply ? 'Responder' : 'Nueva publicación'),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _questionController,
            builder: (context, value, _) {
              final length = value.text.trim().length;
              final canPublish =
                  length > 0 && length <= maxChars && !_sending && !_uploading;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    ForumCharCounter(length: length, maxLength: maxChars),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: canPublish ? _publish : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.neoCyan,
                        foregroundColor: const Color(0xFF06232E),
                        disabledBackgroundColor: AppColors.neoBorder,
                        disabledForegroundColor: AppColors.neoTextMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF06232E),
                              ),
                            )
                          : Text(_isReply ? 'Responder' : 'Publicar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_uploading)
              const LinearProgressIndicator(
                color: AppColors.neoCyan,
                backgroundColor: AppColors.neoSurfaceAlt,
                minHeight: 2,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isReply) ...[
                      _buildParentPreview(widget.parentPost!),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(
                          imageUrl: AuthService.photoUrl ?? '',
                          name: AuthService.displayName,
                          size: 42,
                          borderColor: AppColors.neoCyan.withValues(alpha: 0.5),
                          borderWidth: 1.5,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _questionController,
                            maxLines: null,
                            minLines: 3,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.45,
                            ),
                            cursorColor: AppColors.neoCyan,
                            decoration: InputDecoration(
                              hintText: _isReply
                                  ? 'Escribe tu respuesta'
                                  : '¿Qué está pasando en el foro?',
                              hintStyle: const TextStyle(
                                color: AppColors.neoTextMuted,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showCode) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _codeController,
                        maxLines: 8,
                        style: const TextStyle(
                          color: AppColors.neoCodeText,
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                        cursorColor: AppColors.neoCyan,
                        decoration: InputDecoration(
                          hintText: 'Pega aquí el fragmento de código',
                          hintStyle: const TextStyle(
                            color: AppColors.neoTextMuted,
                            fontFamily: 'monospace',
                          ),
                          filled: true,
                          fillColor: AppColors.neoSurfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.neoBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.neoBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.neoCyan,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_media.isNotEmpty || _uploading) ...[
                      const SizedBox(height: 14),
                      ForumMediaPreview(
                        media: _media,
                        uploading: _uploading,
                        onRemove: _removeMedia,
                      ),
                    ],
                    if (_pollEnabled) ...[
                      const SizedBox(height: 14),
                      _buildPollEditor(),
                    ],
                    if (_location != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          avatar: const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.neoCyan,
                          ),
                          label: Text(_location!),
                          labelStyle: const TextStyle(
                            color: AppColors.neoCyan,
                            fontSize: 12.5,
                          ),
                          backgroundColor: AppColors.neoSurfaceAlt,
                          side: const BorderSide(color: AppColors.neoBorder),
                          onDeleted: () => setState(() => _location = null),
                          deleteIconColor: AppColors.neoTextMuted,
                        ),
                      ),
                    ],
                    _buildTagsPreview(),
                  ],
                ),
              ),
            ),
            ForumComposerBar(
              enabled: !_sending && !_uploading,
              hasPoll: _pollEnabled,
              hasLocation: _location != null,
              hasCode: _showCode,
              onPickImages: _pickImages,
              onTakePhoto: _takePhoto,
              onPickGif: _pickGif,
              onAddPoll: _togglePoll,
              onAddLocation: _editLocation,
              onToggleCode: () => setState(() => _showCode = !_showCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsPreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _questionController,
      builder: (context, value, _) {
        final tags = ForumTrendEngine.extractHashtags(value.text);
        if (tags.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neoCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: AppColors.neoCyan,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 17,
                color: AppColors.neoCyan,
              ),
              const SizedBox(width: 6),
              const Text(
                'Encuesta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _togglePoll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Quitar'),
              ),
            ],
          ),
          for (var index = 0; index < _pollControllers.length; index++) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pollControllers[index],
                    maxLength: 40,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    cursorColor: AppColors.neoCyan,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Opción ${index + 1}',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.neoSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neoBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neoBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.neoCyan,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_pollControllers.length > 2)
                  IconButton(
                    tooltip: 'Quitar opción',
                    onPressed: () => _removePollOption(index),
                    icon: const Icon(
                      Icons.close,
                      size: 17,
                      color: AppColors.neoTextMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (_pollControllers.length < 4)
            TextButton.icon(
              onPressed: _addPollOption,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neoCyan,
                alignment: Alignment.centerLeft,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Añadir opción',
                style: TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParentPreview(ForumPostModel parent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neoSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: parent.authorAvatar,
            name: parent.authorName,
            size: 32,
            borderColor: AppColors.neoCyan.withValues(alpha: 0.5),
            borderWidth: 1.2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondiendo a ${parent.authorName}',
                  style: const TextStyle(
                    color: AppColors.neoCyan,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parent.question,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
