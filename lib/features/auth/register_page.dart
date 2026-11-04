import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/auth_config.dart';
import '../../core/auth_error_messages.dart';
import '../../core/auth_service.dart';
import 'auth_ui.dart';

/// Pantalla de registro con nombre, correo y contraseña.
///
/// Crea la cuenta y deja la sesión iniciada inmediatamente. No se pide
/// confirmar el correo: eso queda preparado en [AuthConfig] para activarlo más
/// adelante.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static final RegExp _emailRegExp = RegExp(
    r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$',
  );

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();

    if (!AuthService.isAvailable) {
      _showMessage(
        'No se pueden crear cuentas en modo demo. Reinicia la app con Firebase '
        'configurado.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // El gate detecta la nueva sesión y muestra la app (o la pantalla de
      // verificación si el flag está activo). Cerramos esta pantalla para que
      // quede visible lo que hay debajo.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('No se pudo crear la cuenta: $e');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'El nombre es obligatorio.';
    if (name.length < 2) return 'Escribe al menos 2 caracteres.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'El correo electrónico es obligatorio.';
    if (!_emailRegExp.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'La contraseña es obligatoria.';
    if (password.length < 6) return 'Usa al menos 6 caracteres.';
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirma tu contraseña.';
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Widget _passwordToggle({
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 19,
        color: AppColors.placeholder,
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPad = size.width < 360 ? 18.0 : 22.0;

    return Scaffold(
      backgroundColor: AppColors.exterior,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: authPanelBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        18,
                        horizontalPad,
                        24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Volver',
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.of(context).maybePop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  authBrandHeader(),
                                ],
                              ),
                              const SizedBox(height: 26),
                              const Text(
                                'Crea tu cuenta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Únete a la comunidad y empieza a compartir tus '
                                'proyectos.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 14.5,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildForm(),
                              const SizedBox(height: 20),
                              _buildLoginLink(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateName,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration: authFieldDecoration(
              icon: Icons.person_outline,
              hint: 'Nombre',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateEmail,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration: authFieldDecoration(
              icon: Icons.mail_outline,
              hint: 'Correo electrónico',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validatePassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration: authFieldDecoration(
              icon: Icons.lock_outline,
              hint: 'Contraseña',
              suffixIcon: _passwordToggle(
                obscure: _obscurePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateConfirm,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration: authFieldDecoration(
              icon: Icons.lock_reset,
              hint: 'Confirmar contraseña',
              suffixIcon: _passwordToggle(
                obscure: _obscureConfirm,
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          if (AuthConfig.requireEmailVerification) ...[
            const SizedBox(height: 10),
            const Text(
              'Te enviaremos un correo para confirmar tu cuenta antes de '
              'entrar.',
              style: TextStyle(
                color: AppColors.placeholder,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: authPrimaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onCyan,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, size: 20),
                      SizedBox(width: 8),
                      Text('Crear cuenta'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '¿Ya tienes cuenta?',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.cyan,
            textStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Inicia sesión'),
        ),
      ],
    );
  }
}
