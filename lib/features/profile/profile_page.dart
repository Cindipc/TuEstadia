import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_theme.dart';
import '../../core/app_links.dart';
import '../../core/auth_error_messages.dart';
import '../../core/auth_service.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/models/forum_post.dart';
import '../../core/models/forum_profile.dart';
import '../../core/models/library_item.dart';
import '../../core/models/pin.dart';
import '../../core/models/project.dart';
import '../../core/repositories/forum_repository.dart';
import '../../core/repositories/pin_repository.dart';
import '../../core/repositories/project_repository.dart';
import '../../core/repositories/user_library_repository.dart';
import '../../core/services/profile_service.dart';
import '../../core/utils/forum_interactions.dart';
import '../../core/utils/project_deletion.dart';
import '../feed/widgets/project_card.dart';
import '../forum/widgets/forum_empty_state.dart';
import '../forum/widgets/forum_post_list.dart';
import '../pins/pin_detail_page.dart';
import 'edit_profile_page.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_library_tile.dart';
import 'widgets/profile_segmented.dart';

/// Perfil del usuario: datos, edición y su actividad en la app.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.onLogout,
    this.userId,
    this.forumRepository,
    this.pinRepository,
    this.projectRepository,
    this.libraryRepository,
    this.profileService,
  });

  final VoidCallback? onLogout;

  /// uid explícito (pruebas). En producción se toma de la sesión.
  final String? userId;

  final ForumRepository? forumRepository;
  final PinRepository? pinRepository;
  final ProjectRepository? projectRepository;
  final UserLibraryRepository? libraryRepository;
  final ProfileService? profileService;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const int _streamCount = 8;

  late final ForumRepository _forumRepository;
  late final PinRepository _pinRepository;
  late final ProjectRepository _projectRepository;
  late final UserLibraryRepository _libraryRepository;
  late final ProfileService _profileService;

  final Set<String> _loaded = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  ForumProfileModel? _profile;
  List<PinModel> _myPins = const [];
  List<PinModel> _savedPins = const [];
  List<ProjectModel> _savedProjects = const [];
  List<ForumPostModel> _myPosts = const [];
  List<ForumPostModel> _likedPosts = const [];
  List<ForumPostModel> _savedPosts = const [];
  List<LibraryItemModel> _library = const [];

  int _postsSegment = 0;
  int _savedSegment = 0;

  String? get _uid => widget.userId ?? AuthService.currentUser?.uid;

  bool get _loading => _loaded.length < _streamCount;

  @override
  void initState() {
    super.initState();
    _forumRepository = widget.forumRepository ?? ForumRepository();
    _pinRepository = widget.pinRepository ?? PinRepository();
    _projectRepository = widget.projectRepository ?? ProjectRepository();
    _libraryRepository = widget.libraryRepository ?? UserLibraryRepository();
    _profileService = widget.profileService ?? ProfileService();

    final uid = _uid;
    if (uid == null) {
      _loaded.addAll(const [
        'profile',
        'myPins',
        'savedPins',
        'savedProjects',
        'myPosts',
        'likedPosts',
        'savedPosts',
        'library',
      ]);
      return;
    }

    _listen('profile', _profileService.watch(uid), (value) => _profile = value);
    _listen(
      'myPins',
      _pinRepository.watchMyPins(uid),
      (value) => _myPins = value,
    );
    _listen(
      'savedPins',
      _pinRepository.watchSavedPins(uid),
      (value) => _savedPins = value,
    );
    _listen(
      'savedProjects',
      _projectRepository.watchSavedProjects(uid),
      (value) => _savedProjects = value,
    );
    _listen(
      'myPosts',
      _forumRepository.watchMyPosts(uid),
      (value) => _myPosts = value,
    );
    _listen(
      'likedPosts',
      _forumRepository.watchLikedPosts(uid),
      (value) => _likedPosts = value,
    );
    _listen(
      'savedPosts',
      _forumRepository.watchSavedPosts(uid),
      (value) => _savedPosts = value,
    );
    _listen(
      'library',
      _libraryRepository.watchMyLibrary(uid),
      (value) => _library = value,
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _listen<T>(String key, Stream<T> stream, void Function(T) onData) {
    _subscriptions.add(
      stream.listen(
        (data) {
          if (!mounted) return;
          setState(() {
            onData(data);
            _loaded.add(key);
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _loaded.add(key));
        },
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _openEdit() async {
    final uid = _uid;
    if (uid == null) {
      _showMessage('Inicia sesión para editar tu perfil.');
      return;
    }

    final initial =
        _profile ??
        ForumProfileModel(
          uid: uid,
          displayName: AuthService.displayName,
          username: (AuthService.email ?? '').split('@').first,
          email: AuthService.email,
          photoUrl: AuthService.photoUrl,
        );

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditProfilePage(initial: initial, service: _profileService),
      ),
    );
    if (updated == true && mounted) {
      _showMessage('Perfil actualizado');
    }
  }

  Future<void> _openLegalLink(String url) async {
    final opened = await openAppLink(url);
    if (!mounted || opened) return;
    _showMessage('No se pudo abrir el enlace.');
  }

  Future<void> _confirmDeleteAccount() async {
    if (_uid == null) {
      _showMessage('Inicia sesión para eliminar tu cuenta.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neoSurface,
        title: const Text(
          'Eliminar mi cuenta',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Se eliminarán de forma permanente tu perfil, publicaciones, pines, '
          'proyectos, biblioteca e interacciones. Esta acción no se puede '
          'deshacer.',
          style: TextStyle(color: AppColors.neoTextMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final user = AuthService.currentUser;
    final needsPassword =
        user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;

    String? password;
    if (needsPassword) {
      password = await _askPasswordForDeletion();
      if (password == null || !mounted) return;
    }

    try {
      await AuthService.deleteAccount(password: password);
      if (!mounted) return;
      widget.onLogout?.call();
      _showMessage('Tu cuenta fue eliminada.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo eliminar la cuenta: $e');
    }
  }

  Future<String?> _askPasswordForDeletion() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.neoSurface,
        title: const Text(
          'Confirma tu contraseña',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: AppColors.neoCyan,
          decoration: const InputDecoration(
            hintText: 'Contraseña actual',
            hintStyle: TextStyle(color: AppColors.neoTextMuted),
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _togglePinSave(PinModel pin) async {
    final uid = _uid;
    if (uid == null) {
      _showMessage('Inicia sesión para guardar.');
      return;
    }
    final ok = await _pinRepository.toggleSave(
      pinId: pin.id,
      uid: uid,
      currentlySaved: pin.isSavedBy(uid),
    );
    if (!mounted || ok) return;
    _showMessage(
      FirebaseBootstrap.isAvailable
          ? 'No se pudo guardar. Revisa tu sesión y las reglas.'
          : 'Modo demo: los cambios no se guardan.',
    );
  }

  Future<void> _toggleSavedItem(ProjectModel project) async {
    final uid = _uid;
    if (uid == null) {
      _showMessage('Inicia sesión para guardar.');
      return;
    }

    final saved = project.isSavedBy(uid) || project.saved;
    final ok = project.source == ProjectSource.pin
        ? await _pinRepository.toggleSave(
            pinId: project.id,
            uid: uid,
            currentlySaved: saved,
          )
        : await _projectRepository.toggleSave(project, uid);

    if (!mounted || ok) return;
    _showMessage(
      FirebaseBootstrap.isAvailable
          ? 'No se pudo guardar. Revisa tu sesión y las reglas.'
          : 'Modo demo: los cambios no se guardan.',
    );
  }

  Future<void> _openLibraryItem(LibraryItemModel item) async {
    final link = item.webViewLink;
    if (link == null || link.isEmpty) {
      _showMessage('Este elemento no tiene un enlace disponible.');
      return;
    }
    final opened = await launchUrl(
      Uri.parse(link),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || opened) return;
    _showMessage('No se pudo abrir el archivo.');
  }

  Future<void> _removeLibraryItem(LibraryItemModel item) async {
    final ok = await _libraryRepository.removeItem(item.id);
    if (!mounted || ok) return;
    _showMessage('No se pudo quitar de tu biblioteca.');
  }

  Future<void> _confirmDeleteProject(ProjectModel project) async {
    final uid = _uid;
    if (uid == null || !project.isOwnedBy(uid)) return;

    final confirmed = await confirmDeletion(context);
    if (!confirmed || !mounted) return;

    final ok = await deleteProjectItem(
      project: project,
      pinRepository: _pinRepository,
      projectRepository: _projectRepository,
    );
    if (!mounted) return;

    if (!ok) {
      _showMessage(
        FirebaseBootstrap.isAvailable
            ? 'No se pudo eliminar. Revisa tu sesión y las reglas.'
            : 'Modo demo: no se puede eliminar.',
      );
      return;
    }
    _showMessage('Publicación eliminada');
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final name = profile?.displayName ?? AuthService.displayName;
    final email = profile?.email ?? AuthService.email;
    final username = (profile?.username ?? '').isNotEmpty
        ? profile!.username
        : (email ?? '').contains('@')
        ? email!.split('@').first
        : '';
    final bio = profile?.bio ?? '';
    final photo = profile?.photoUrl ?? AuthService.photoUrl ?? '';
    final banner = profile?.bannerUrl ?? '';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.neoBackground,
        appBar: AppBar(
          backgroundColor: AppColors.neoBackground,
          title: const Text('Perfil'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              color: AppColors.neoSurface,
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _openEdit();
                  case 'privacy':
                    _openLegalLink(AppLinks.privacyPolicy);
                  case 'terms':
                    _openLegalLink(AppLinks.terms);
                  case 'delete':
                    _confirmDeleteAccount();
                  case 'logout':
                    widget.onLogout?.call();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.neoTextMuted,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Editar perfil',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 18,
                        color: AppColors.neoTextMuted,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Privacidad',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'terms',
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: AppColors.neoTextMuted,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Términos',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Eliminar cuenta',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Cerrar sesión',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              ProfileHeader(
                name: name,
                username: username,
                bio: bio,
                photoUrl: photo,
                bannerUrl: banner,
                isDemo: !FirebaseBootstrap.isAvailable,
                stats: [
                  ProfileStat(
                    label: 'Publicaciones',
                    value:
                        _myPins.length +
                        _myPosts.where((post) => post.isRoot).length,
                  ),
                  ProfileStat(label: 'Me gusta', value: _likedPosts.length),
                  ProfileStat(
                    label: 'Guardados',
                    value:
                        _savedPins.length +
                        _savedPosts.length +
                        _savedProjects.length,
                  ),
                  ProfileStat(label: 'Biblioteca', value: _library.length),
                ],
                onTapBanner: _openEdit,
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.neoCyan,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.neoTextMuted,
                dividerColor: AppColors.neoBorder,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: 'Publicaciones'),
                  Tab(text: 'Me gusta'),
                  Tab(text: 'Guardados'),
                  Tab(text: 'Biblioteca'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPostsTab(),
                    _buildLikesTab(),
                    _buildSavedTab(),
                    _buildLibraryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_loading) return const _LoadingTab();
    if (_uid == null) {
      return const _EmptyTab(
        icon: Icons.person_outline,
        title: 'Inicia sesión',
        message: 'Necesitas una cuenta para ver tu actividad.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ProfileSegmented(
            options: const ['Pines', 'Posts del foro'],
            selectedIndex: _postsSegment,
            onChanged: (index) => setState(() => _postsSegment = index),
          ),
        ),
        Expanded(
          child: _postsSegment == 0
              ? _buildPinsGrid(
                  _myPins,
                  emptyTitle: 'Aún no has creado pines',
                  emptyMessage:
                      'Toca el + del feed para compartir tu primer proyecto.',
                )
              : _buildPostsList(
                  _myPosts,
                  emptyTitle: 'Aún no has publicado en el foro',
                  emptyMessage: 'Pregunta tus dudas desde la pestaña Foro y aparecerán aquí.',
                ),
        ),
      ],
    );
  }

  Widget _buildLikesTab() {
    if (_loading) return const _LoadingTab();
    return _buildPostsList(
      _likedPosts,
      emptyTitle: 'Todavía no te gusta nada',
      emptyMessage: 'Los posts del foro a los que des "Like" aparecerán aquí.',
    );
  }

  Widget _buildSavedTab() {
    if (_loading) return const _LoadingTab();

    final savedProjects = <ProjectModel>[
      ..._savedPins.map((pin) => pin.toProject()),
      ..._savedProjects,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ProfileSegmented(
            options: const ['Pines', 'Posts'],
            selectedIndex: _savedSegment,
            onChanged: (index) => setState(() => _savedSegment = index),
          ),
        ),
        Expanded(
          child: _savedSegment == 0
              ? _buildPinsGrid(
                  const [],
                  models: savedProjects,
                  emptyTitle: 'No tienes pines guardados',
                  emptyMessage:
                      'Guarda proyectos desde el feed con el marcador.',
                )
              : _buildPostsList(
                  _savedPosts,
                  emptyTitle: 'No tienes posts guardados',
                  emptyMessage:
                      'Guarda publicaciones del foro con el marcador.',
                ),
        ),
      ],
    );
  }

  Widget _buildLibraryTab() {
    if (_loading) return const _LoadingTab();
    if (_uid == null) {
      return const _EmptyTab(
        icon: Icons.folder_open,
        title: 'Inicia sesión',
        message: 'Necesitas una cuenta para tener tu biblioteca.',
      );
    }
    if (_library.isEmpty) {
      return const _EmptyTab(
        icon: Icons.folder_open,
        title: 'Tu biblioteca está vacía',
        message: 'Abre la pestaña Biblioteca y añade archivos a tu perfil con el marcador.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: _library.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _library[index];
        return ProfileLibraryTile(
          item: item,
          onOpen: () => _openLibraryItem(item),
          onRemove: () => _removeLibraryItem(item),
        );
      },
    );
  }

  Widget _buildPostsList(
    List<ForumPostModel> posts, {
    required String emptyTitle,
    required String emptyMessage,
  }) {
    return ForumPostList(
      posts: posts,
      repository: _forumRepository,
      currentUserId: forumInteractionUid(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      emptyState: _EmptyTab(
        icon: Icons.forum_outlined,
        title: emptyTitle,
        message: emptyMessage,
      ),
    );
  }

  Widget _buildPinsGrid(
    List<PinModel> pins, {
    List<ProjectModel> models = const [],
    required String emptyTitle,
    required String emptyMessage,
  }) {
    final items = <ProjectModel>[
      ...pins.map((pin) => pin.toProject().forUser(_uid)),
      ...models.map((model) => model.forUser(_uid)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (items.isEmpty) {
      return _EmptyTab(
        icon: Icons.push_pin_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final project = items[index];
        return ProjectCard(
          project: project,
          imageHeight: 150,
          onDelete: project.isOwnedBy(_uid)
              ? () => _confirmDeleteProject(project)
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PinDetailPage(project: project)),
          ),
          onToggleSave: () {
            if (project.source == ProjectSource.pin) {
              final pin = pins.where((item) => item.id == project.id);
              if (pin.isNotEmpty) {
                _togglePinSave(pin.first);
                return;
              }
            }
            _toggleSavedItem(project);
          },
        );
      },
    );
  }
}

class _LoadingTab extends StatelessWidget {
  const _LoadingTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.neoCyan),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ForumEmptyState(icon: icon, title: title, message: message);
  }
}
