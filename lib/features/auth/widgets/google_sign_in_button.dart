import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Botón de Google reutilizado por el login y el registro.
///
/// `AuthService.signInWithGoogle()` inicia sesión si la cuenta existe y la crea
/// automáticamente si es la primera vez, así que el mismo botón sirve para los
/// dos flujos.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.label = 'Continuar con Google',
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF16243C),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF16243C),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        side: const BorderSide(color: AppColors.fieldBorder, width: 1),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 20, height: 20, child: GoogleLogo()),
                  const SizedBox(width: 10),
                  Text(label),
                ],
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
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)')
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
    if (tokens[index].length == 1 &&
        !RegExp(r'[0-9.\-]').hasMatch(tokens[index])) {
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
