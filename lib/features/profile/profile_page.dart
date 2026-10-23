import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/widgets/app_avatar.dart';

/// Pantalla de perfil (placeholder funcional para la navegación principal).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
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
            onPressed: onLogout,
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
                  const AppAvatar(
                    imageUrl: 'https://i.pravatar.cc/120?img=45',
                    name: 'Tu Estadia',
                    size: 58,
                    borderColor: AppColors.neoCyan,
                    borderWidth: 2,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu Estadia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aprende, comparte y programa junto a otros.',
                          style: TextStyle(
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
          ],
        ),
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
