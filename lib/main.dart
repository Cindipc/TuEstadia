import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'core/auth_service.dart';
import 'core/firebase_bootstrap.dart';
import 'features/shell/main_shell.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const TuEstadiaApp());
}

class TuEstadiaApp extends StatelessWidget {
  const TuEstadiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuEstadia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.neoDark,
      darkTheme: AppTheme.neoDark,
      themeMode: ThemeMode.dark,
      home: const _AuthGate(),
    );
  }
}

/// Decide qué mostrar según el estado de autenticación de Firebase.
///
/// - Firebase configurado: `FirebaseAuth.authStateChanges()`.
/// - Firebase sin configurar (o sin soporte, como Linux): modo demo.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _demoMode = false;

  @override
  Widget build(BuildContext context) {
    // Modo demo: se puede entrar con o sin Firebase configurado.
    if (_demoMode) {
      return MainShell(onLogout: () => setState(() => _demoMode = false));
    }

    if (!FirebaseBootstrap.isAvailable) {
      return LoginPage(onAuthenticated: () => setState(() => _demoMode = true));
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.neoCyan),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginPage(
            onAuthenticated: () => setState(() => _demoMode = true),
          );
        }

        return MainShell(
          onLogout: () async {
            await AuthService.signOut();
          },
        );
      },
    );
  }
}
