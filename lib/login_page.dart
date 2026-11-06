import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_theme.dart';
import 'core/app_links.dart';
import 'core/auth_error_messages.dart';
import 'core/auth_service.dart';
import 'core/firebase_bootstrap.dart';
import 'features/auth/auth_ui.dart';
import 'features/auth/register_page.dart';
import 'features/auth/widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onDemoMode});

  /// Se invoca cuando el usuario elige explorar en modo demo.
  ///
  /// El inicio de sesión real no usa este callback: lo detecta el `_AuthGate`
  /// a través de `AuthService.authStateChanges()`.
  final VoidCallback? onDemoMode;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)+$');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;

  bool get _busy => _isLoading || _googleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    if (!FirebaseBootstrap.isAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(
        'Firebase no está configurado. Entra en modo demo para explorar la app.',
      );
      return;
    }

    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('No se pudo iniciar sesión: $e');
    }
  }

  Future<void> _openRegister() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterPage()));
  }

  Future<void> _onForgotPassword() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage(
        'Escribe tu correo para enviarte el enlace de recuperación.',
      );
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      _showMessage('Ingresa un correo electrónico válido.');
      return;
    }
    if (!AuthService.isAvailable) {
      _showMessage(
        'Firebase no está configurado. Entra en modo demo para explorar la app.',
      );
      return;
    }

    try {
      await AuthService.sendPasswordReset(email);
      if (!mounted) return;
      _showMessage('Te enviamos un enlace de recuperación a $email.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo enviar el correo: $e');
    }
  }

  void _onDemoPressed() {
    if (_busy) return;
    widget.onDemoMode?.call();
  }

  Future<void> _onGooglePressed() async {
    if (_busy) return;
    if (!AuthService.isAvailable) {
      _showMessage(
        'Firebase no está configurado. Entra en modo demo para explorar la app.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _googleLoading = true);

    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      setState(() => _googleLoading = false);
    } on GoogleSignInException catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      // Cancelar el selector de cuentas no es un error que deba mostrarse.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _showMessage(googleSignInErrorMessage(e));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      _showMessage(authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      _showMessage('No se pudo iniciar sesión con Google: $e');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    return null;
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    required String hint,
  }) {
    return authFieldDecoration(icon: icon, hint: hint);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final horizontalPad = size.width < 360 ? 18.0 : 22.0;
    final contentWidth = (size.width - 16 - horizontalPad * 2).clamp(
      0.0,
      460.0,
    );
    final titleSize = (contentWidth * 0.118).clamp(26.0, 44.0);

    final topPad = compact ? 20.0 : 28.0;
    final headerGap = compact ? 20.0 : 26.0;
    final titleGap = compact ? 10.0 : 14.0;
    final descriptionGap = compact ? 22.0 : 30.0;
    final fieldGap = compact ? 12.0 : 14.0;
    final buttonGap = compact ? 18.0 : 22.0;
    final separatorGap = compact ? 16.0 : 22.0;
    final googleGap = compact ? 12.0 : 14.0;
    final footerGap = compact ? 20.0 : 28.0;
    final bottomPad = compact ? 14.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.panelTop,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.panelTop, AppColors.panelBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPad,
                              topPad,
                              horizontalPad,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                SizedBox(height: headerGap),
                                _buildTitle(titleSize),
                                SizedBox(height: titleGap),
                                const Text(
                                  'Únete a la comunidad de estudiantes de TI más grande.',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 15,
                                    height: 1.45,
                                  ),
                                ),
                                SizedBox(height: descriptionGap),
                                _buildForm(fieldGap, buttonGap),
                                SizedBox(height: separatorGap),
                                _buildSeparator(),
                                SizedBox(height: googleGap),
                                _buildGoogleButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPad,
                          footerGap,
                          horizontalPad,
                          bottomPad,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _buildRegisterLink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return authBrandHeader();
  }

  Widget _buildTitle(double titleSize) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: titleSize,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        children: const [
          TextSpan(text: 'Aprende,\ncomparte y\nprograma\n'),
          TextSpan(
            text: 'junto a otros.',
            style: TextStyle(color: AppColors.cyan),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(double fieldGap, double buttonGap) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            decoration: _fieldDecoration(
              icon: Icons.mail_outline,
              hint: 'Correo electrónico',
            ),
          ),
          SizedBox(height: fieldGap),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration:
                _fieldDecoration(
                  icon: Icons.lock_outline,
                  hint: 'Contraseña',
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                      color: AppColors.placeholder,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.placeholder,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          SizedBox(height: buttonGap),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan,
              disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.5),
              foregroundColor: AppColors.onCyan,
              disabledForegroundColor: AppColors.onCyan.withValues(alpha: 0.7),
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
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
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Ingresar'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    const line = Expanded(
      child: Divider(color: AppColors.fieldBorder, thickness: 1, height: 20),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'O continúa con',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        line,
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleSignInButton(
          loading: _googleLoading,
          onPressed: _busy ? null : _onGooglePressed,
        ),
        const SizedBox(height: 8),
        const Text(
          'Si no tienes cuenta, se crea automáticamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.placeholder,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Al continuar aceptas los ',
              style: TextStyle(
                color: AppColors.placeholder,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            _legalLink('términos', AppLinks.terms),
            const Text(
              ' y la ',
              style: TextStyle(
                color: AppColors.placeholder,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            _legalLink('política de privacidad', AppLinks.privacyPolicy),
            const Text(
              '.',
              style: TextStyle(
                color: AppColors.placeholder,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legalLink(String text, String url) {
    return GestureDetector(
      onTap: () => openAppLink(url),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 11.5,
          height: 1.35,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _busy ? null : _openRegister,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(text: '¿No tienes cuenta? '),
                    TextSpan(
                      text: 'Regístrate',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _onDemoPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.placeholder,
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Explorar en modo demo'),
        ),
      ],
    );
  }
}
