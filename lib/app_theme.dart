import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0F172A); // Azul marino muy oscuro (fondo)
  static const surface = Color(0xFF1E293B); // Azul oscuro de contraste (cards)
  static const accent = Color(0xFF38BDF8); // Azul eléctrico (botones y enlaces)
  static const primary = Color(0xFF0EA5E9); // Cian vibrante (botones y enlaces)
  static const successDark = Color(0xFF0D9488); // Verde turquesa (estatus)
  static const success = Color(0xFF10B981); // Verde esmeralda (progreso)
  static const textPrimary = Color(0xFFF1F5F9); // Blanco apagado (texto)
  static const textSecondary = Color(0xFF64748B); // Gris azulado (secundario)

  // Pantalla de login
  static const exterior = Color(0xFFF1F5F9); // Gris muy claro del entorno
  static const panelTop = Color(0xFF0A1B33); // Azul marino oscuro
  static const panelBottom = Color(0xFF0C3B4A); // Azul petróleo (degradado)
  static const panelDeep = Color(0xFF061526); // Símbolo del logo
  static const cyan = Color(0xFF22D3EE); // Cian de acento
  static const onCyan = Color(0xFF06232E); // Texto sobre cian
  static const fieldFill = Color(0xFF1C2A41); // Azul grisáceo de campos
  static const fieldBorder = Color(0xFF3A4A63); // Bordes finos
  static const placeholder = Color(0xFF8FA3C0); // Placeholders gris azulados
  static const muted = Color(0xFF94A3B8); // Descripción gris azulada
  static const error = Color(0xFFF87171); // Mensajes de error
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: AppColors.background,
          tertiary: AppColors.success,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.success,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.cyan,
          onSecondary: AppColors.panelDeep,
          surface: AppColors.exterior,
          onSurface: const Color(0xFF0F172A),
          error: AppColors.error,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.exterior,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.35,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
