import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../feed/home_page.dart';
import '../forum/forum_page.dart';
import '../library/library_page.dart';
import '../profile/profile_page.dart';

/// Contenedor principal con la navegación inferior de la app.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goToFeed() {
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      LibraryPage(onBack: _goToFeed),
      const ForumPage(),
      ProfilePage(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.neoBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Biblioteca',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Foro',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
