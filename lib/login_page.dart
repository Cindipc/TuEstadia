import 'package:flutter/material.dart';

import 'app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future<void>.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage('La autenticación todavía no está disponible en esta versión.');
  }

  void _onGooglePressed() {
    if (_isLoading) return;
    _showMessage('El inicio de sesión con Google todavía no está configurado.');
  }

  void _onRegisterPressed() {
    _showMessage('La creación de cuentas todavía no está disponible.');
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
    const radius = BorderRadius.all(Radius.circular(14));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 15),
      prefixIcon: Icon(icon, size: 20),
      prefixIconColor: AppColors.placeholder,
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12.5,
        height: 1.3,
      ),
      errorMaxLines: 2,
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.fieldBorder, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;
    final horizontalPad = size.width < 360 ? 18.0 : 22.0;
    final contentWidth =
        (size.width - 16 - horizontalPad * 2).clamp(0.0, 460.0);
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
      backgroundColor: AppColors.exterior,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.panelTop, AppColors.panelBottom],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Icon(Icons.hexagon, size: 34, color: AppColors.cyan),
              Icon(Icons.code_rounded, size: 16, color: AppColors.panelDeep),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'CodeShare',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
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
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: AppColors.cyan,
            decoration: _fieldDecoration(
              icon: Icons.lock_outline,
              hint: 'Contraseña',
            ),
          ),
          SizedBox(height: buttonGap),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
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
    return OutlinedButton(
      onPressed: _onGooglePressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF16243C),
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.fieldBorder, width: 1),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 20, height: 20, child: GoogleLogo()),
          SizedBox(width: 10),
          Text('Google'),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _onRegisterPressed,
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
    );
  }
}

/// Icono oficial de la "G" de Google dibujado sin dependencias externas.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleLogoPainter(),
      size: const Size.square(20),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);

  static const _greenPath =
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
      '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z';
  static const _yellowPath =
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
      'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z';
  static const _bluePath =
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
      '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z';
  static const _redPath =
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
      '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z';

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48;
    canvas.save();
    canvas.scale(scale, scale);

    void draw(String data, Color color) {
      canvas.drawPath(
        _parseSvgPath(data),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    draw(_greenPath, _green);
    draw(_yellowPath, _yellow);
    draw(_bluePath, _blue);
    draw(_redPath, _red);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

Path _parseSvgPath(String source) {
  final path = Path();
  final tokens =
      RegExp(r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)')
          .allMatches(source)
          .map((match) => match.group(0)!)
          .toList();

  var index = 0;
  double next() => double.parse(tokens[index++]);

  String? command;
  var currentX = 0.0;
  var currentY = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  var controlX = 0.0;
  var controlY = 0.0;
  var hasControlPoint = false;

  while (index < tokens.length) {
    if (tokens[index].length == 1 && !RegExp(r'[0-9.\-]').hasMatch(tokens[index])) {
      command = tokens[index];
      index++;
    }
    if (command == null) break;

    final relative = command == command.toLowerCase();
    final upper = command.toUpperCase();

    switch (upper) {
      case 'M':
        final x = next();
        final y = next();
        currentX = relative ? currentX + x : x;
        currentY = relative ? currentY + y : y;
        path.moveTo(currentX, currentY);
        startX = currentX;
        startY = currentY;
        hasControlPoint = false;
        command = relative ? 'l' : 'L';
      case 'L':
        final x = next();
        final y = next();
        currentX = relative ? currentX + x : x;
        currentY = relative ? currentY + y : y;
        path.lineTo(currentX, currentY);
        hasControlPoint = false;
      case 'H':
        final x = next();
        currentX = relative ? currentX + x : x;
        path.lineTo(currentX, currentY);
        hasControlPoint = false;
      case 'V':
        final y = next();
        currentY = relative ? currentY + y : y;
        path.lineTo(currentX, currentY);
        hasControlPoint = false;
      case 'C':
        final x1 = next();
        final y1 = next();
        final x2 = next();
        final y2 = next();
        final x = next();
        final y = next();
        final c1x = relative ? currentX + x1 : x1;
        final c1y = relative ? currentY + y1 : y1;
        final c2x = relative ? currentX + x2 : x2;
        final c2y = relative ? currentY + y2 : y2;
        final endX = relative ? currentX + x : x;
        final endY = relative ? currentY + y : y;
        path.cubicTo(c1x, c1y, c2x, c2y, endX, endY);
        controlX = c2x;
        controlY = c2y;
        currentX = endX;
        currentY = endY;
        hasControlPoint = true;
      case 'S':
        final x2 = next();
        final y2 = next();
        final x = next();
        final y = next();
        final c1x = hasControlPoint ? 2 * currentX - controlX : currentX;
        final c1y = hasControlPoint ? 2 * currentY - controlY : currentY;
        final c2x = relative ? currentX + x2 : x2;
        final c2y = relative ? currentY + y2 : y2;
        final endX = relative ? currentX + x : x;
        final endY = relative ? currentY + y : y;
        path.cubicTo(c1x, c1y, c2x, c2y, endX, endY);
        controlX = c2x;
        controlY = c2y;
        currentX = endX;
        currentY = endY;
        hasControlPoint = true;
      case 'Z':
        path.close();
        currentX = startX;
        currentY = startY;
        hasControlPoint = false;
      default:
        index++;
    }
  }

  return path;
}
