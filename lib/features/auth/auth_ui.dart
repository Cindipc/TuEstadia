import 'package:flutter/material.dart';

import '../../app_theme.dart';

/// Piezas visuales compartidas por el login y el registro.
///
/// Mantenerlas en un solo lugar evita que las dos pantallas se desalineen.

/// Decoración de los campos de texto de autenticación.
InputDecoration authFieldDecoration({
  required IconData icon,
  required String hint,
  Widget? suffixIcon,
}) {
  const radius = BorderRadius.all(Radius.circular(14));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 15),
    prefixIcon: Icon(icon, size: 20),
    prefixIconColor: AppColors.placeholder,
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: suffixIcon,
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

/// Encabezado con el logo y el nombre de la app.
Widget authBrandHeader() {
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
        'TuEstadia',
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

/// Estilo del botón principal de las pantallas de autenticación.
ButtonStyle authPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.cyan,
    disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.5),
    foregroundColor: AppColors.onCyan,
    disabledForegroundColor: AppColors.onCyan.withValues(alpha: 0.7),
    minimumSize: const Size.fromHeight(52),
    padding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}

/// Contenedor con el degradado de fondo del panel de autenticación.
Widget authPanelBackground({required Widget child}) {
  return DecoratedBox(
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
    child: child,
  );
}
