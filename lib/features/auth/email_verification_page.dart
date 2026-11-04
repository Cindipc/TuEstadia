import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/auth_config.dart';
import '../../core/auth_error_messages.dart';
import '../../core/auth_service.dart';

/// Pantalla que bloquea el acceso hasta confirmar el correo.
///
/// Solo se muestra cuando [AuthConfig.requireEmailVerification] está activo.
/// Con el registro inmediato (por defecto) esta pantalla nunca aparece.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onSignOut,
  });

  final String email;
  final VoidCallback onVerified;
  final VoidCallback onSignOut;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _checking = false;
  bool _resending = false;
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldownSeconds = AuthConfig.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _cooldownSeconds > 0) return;
    setState(() => _resending = true);

    try {
      await AuthService.sendVerificationEmail();
      if (!mounted) return;
      setState(() => _resending = false);
      _startCooldown();
      _showMessage('Correo reenviado a ${widget.email}.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);
      _showMessage('No se pudo reenviar el correo: $e');
    }
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final user = await AuthService.reloadAndCheckVerified();
      if (!mounted) return;
      setState(() => _checking = false);

      if (user?.emailVerified ?? false) {
        widget.onVerified();
      } else {
        _showMessage(
          'Tu correo todavía no aparece como verificado. Abre el enlace del '
          'correo y vuelve a intentarlo.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      _showMessage('No se pudo comprobar la verificación: $e');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.neoCyan,
                    size: 52,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Confirma tu correo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: AppColors.neoTextMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Enviamos un enlace de verificación a ',
                        ),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: AppColors.neoCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '. Ábrelo y después pulsa «Ya verifiqué mi '
                              'correo». Revisa también la carpeta de spam.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  FilledButton.icon(
                    onPressed: _checking ? null : _checkVerified,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.neoCyan,
                      foregroundColor: const Color(0xFF06232E),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _checking
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF06232E),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 19),
                    label: const Text(
                      'Ya verifiqué mi correo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                        _resending || _cooldownSeconds > 0 ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neoCyan,
                      side: const BorderSide(color: AppColors.neoBorder),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _resending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.neoCyan,
                            ),
                          )
                        : Text(
                            _cooldownSeconds > 0
                                ? 'Reenviar en ${_cooldownSeconds}s'
                                : 'Reenviar correo',
                          ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: widget.onSignOut,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.neoTextMuted,
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
