import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/models/forum_profile.dart';
import '../../core/services/profile_service.dart';

/// Edición del perfil: foto, nombre, @usuario y bio.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.initial, this.service});

  final ForumProfileModel initial;
  final ProfileService? service;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static final RegExp _usernameRegExp = RegExp(r'^[a-z0-9._]{2,20}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final ProfileService _service;
  final ImagePicker _picker = ImagePicker();

  String? _photoUrl;
  String? _bannerUrl;
  bool _uploading = false;
  bool _uploadingBanner = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ProfileService();
    final initial = widget.initial;
    final fallbackUsername = (initial.email ?? '').split('@').first;
    _nameController = TextEditingController(text: initial.displayName);
    _usernameController = TextEditingController(
      text: initial.username.isNotEmpty ? initial.username : fallbackUsername,
    );
    _bioController = TextEditingController(text: initial.bio);
    _photoUrl = initial.photoUrl;
    _bannerUrl = initial.bannerUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAvatar() async {
    if (_uploading) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );
      if (file == null) return;

      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final url = await _service.uploadImage(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _uploading = false);

      if (url == null) {
        _showMessage('No se pudo subir la imagen. Inténtalo de nuevo.');
        return;
      }
      setState(() => _photoUrl = url);
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showMessage('No se pudo abrir la imagen: $error');
    }
  }

  Future<void> _pickBanner() async {
    if (_uploadingBanner) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;

      setState(() => _uploadingBanner = true);
      final bytes = await file.readAsBytes();
      final url = await _service.uploadImage(
        bytes: bytes,
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _uploadingBanner = false);

      if (url == null) {
        _showMessage('No se pudo subir la portada. Inténtalo de nuevo.');
        return;
      }
      setState(() => _bannerUrl = url);
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingBanner = false);
      _showMessage('No se pudo abrir la imagen: $error');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final uid = widget.initial.uid;
    if (uid.isEmpty) {
      _showMessage('Inicia sesión para editar tu perfil.');
      return;
    }

    setState(() => _saving = true);
    final ok = await _service.updateProfile(
      uid: uid,
      displayName: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      photoUrl: _photoUrl,
      bannerUrl: _bannerUrl,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo guardar el perfil. Revisa tu conexión y las reglas.'
            : 'Modo demo: los cambios no se guardan.',
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _changePassword() async {
    final email = AuthService.email ?? widget.initial.email;
    if (email == null || email.isEmpty) {
      _showMessage('Tu cuenta no tiene un correo asociado.');
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      _showMessage('Te enviamos un enlace para cambiar la contraseña a $email.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('No se pudo enviar el correo de recuperación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();

    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        title: const Text('Editar perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving || _uploading || _uploadingBanner
                  ? null
                  : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.neoCyan,
                foregroundColor: const Color(0xFF06232E),
                disabledBackgroundColor: AppColors.neoBorder,
                disabledForegroundColor: AppColors.neoTextMuted,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF06232E),
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              _buildBanner(),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.neoCyan.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 104,
                            height: 104,
                            child: _buildAvatar(name),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.neoCyan,
                            shape: BoxShape.circle,
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF06232E),
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 17,
                                  color: Color(0xFF06232E),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _uploading ? null : _pickAvatar,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neoCyan,
                  ),
                  child: Text(_uploading ? 'Subiendo…' : 'Cambiar foto'),
                ),
              ),
              const SizedBox(height: 12),
              _label('Nombre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: AppColors.neoCyan,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final name = (value ?? '').trim();
                  if (name.isEmpty) return 'El nombre es obligatorio.';
                  if (name.length < 2) return 'Usa al menos 2 caracteres.';
                  return null;
                },
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Tu nombre'),
              ),
              const SizedBox(height: 18),
              _label('Usuario'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: AppColors.neoCyan,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final username = (value ?? '').trim().toLowerCase();
                  if (username.isEmpty) return 'El usuario es obligatorio.';
                  if (!_usernameRegExp.hasMatch(username)) {
                    return 'Usa 2-20 caracteres: letras, números, punto o guion bajo.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  prefixText: '@',
                  prefixStyle: TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 15,
                  ),
                  hintText: 'usuario',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _label('Bio'),
                  const Spacer(),
                  Text(
                    '${_bioController.text.length}/160',
                    style: TextStyle(
                      color: _bioController.text.length > 160
                          ? AppColors.error
                          : AppColors.neoTextMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 160,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                cursorColor: AppColors.neoCyan,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cuéntale a la comunidad a qué te dedicas',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 26),
              OutlinedButton.icon(
                onPressed: _changePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neoCyan,
                  side: const BorderSide(color: AppColors.neoBorder),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.lock_reset, size: 18),
                label: const Text('Cambiar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final url = _bannerUrl;
    final hasBanner = url != null && url.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        onTap: _uploadingBanner ? null : _pickBanner,
        child: Container(
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neoBorder),
            gradient: hasBanner
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.neoCyan.withValues(alpha: 0.28),
                      AppColors.neoEmerald.withValues(alpha: 0.18),
                      AppColors.neoSurface,
                    ],
                  ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasBanner)
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              if (!hasBanner)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.neoTextMuted,
                        size: 24,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Añadir portada',
                        style: TextStyle(
                          color: AppColors.neoTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_uploadingBanner)
                const ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.neoCyan,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: hasBanner ? 'Cambiar portada' : 'Subir portada',
                      onPressed: _uploadingBanner ? null : _pickBanner,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.photo_camera_outlined,
                        size: 17,
                      ),
                    ),
                    if (hasBanner) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Quitar portada',
                        onPressed: () => setState(() => _bannerUrl = null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final url = _photoUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.neoSurfaceAlt,
        alignment: Alignment.center,
        child: Text(
          name.isEmpty
              ? '?'
              : name
                    .trim()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((part) => part[0])
                    .join()
                    .toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: AppColors.neoSurfaceAlt,
        child: Icon(Icons.person, color: AppColors.neoTextMuted, size: 40),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.neoTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}
