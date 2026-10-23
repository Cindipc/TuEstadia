import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/firebase_bootstrap.dart';
import '../../core/seed_service.dart';
import '../../core/widgets/app_avatar.dart';

/// Pantalla de perfil con datos de la sesión de Firebase y utilidades.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _seeding = false;

  Future<void> _seedDemoData() async {
    if (_seeding) return;
    setState(() => _seeding = true);

    final result = await SeedService.seedDemoData();

    if (!mounted) return;
    setState(() => _seeding = false);

    final icon = switch (result.status) {
      SeedStatus.success => Icons.check_circle_outline,
      SeedStatus.permissionDenied => Icons.lock_outline,
      _ => Icons.error_outline,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.neoCyan),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message ?? 'Listo')),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.displayName;
    final email = AuthService.email;
    final photo = AuthService.photoUrl;
    final connected = FirebaseBootstrap.isAvailable;

    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            color: AppColors.neoTextMuted,
            onPressed: widget.onLogout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.neoSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neoBorder),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: photo ?? '',
                    name: name,
                    size: 58,
                    borderColor: AppColors.neoCyan,
                    borderWidth: 2,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email ?? 'Aprende, comparte y programa junto a otros.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neoTextMuted,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _StatCard(value: '12', label: 'Proyectos')),
                SizedBox(width: 12),
                Expanded(child: _StatCard(value: '8', label: 'Guardados')),
                SizedBox(width: 12),
                Expanded(child: _StatCard(value: '24', label: 'Respuestas')),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Conexión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _StatusTile(
              icon: connected ? Icons.cloud_done_outlined : Icons.cloud_off,
              color: connected ? AppColors.neoEmerald : AppColors.neoTextMuted,
              title: connected
                  ? 'Firestore conectado'
                  : 'Modo demo (sin Firebase)',
              subtitle: connected
                  ? 'Proyecto: ${FirebaseBootstrap.projectId ?? 'desconocido'}'
                  : FirebaseBootstrap.error ??
                        'Configura las credenciales para guardar datos.',
            ),
            if (connected) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _seeding ? null : _seedDemoData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neoCyan,
                    side: const BorderSide(color: AppColors.neoCyan),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _seeding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neoCyan,
                          ),
                        )
                      : const Icon(Icons.upload_file, size: 18),
                  label: const Text('Cargar datos de prueba en Firestore'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neoSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.neoTextMuted,
                    fontSize: 11.5,
                    height: 1.35,
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.neoSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.neoCyan,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neoTextMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
