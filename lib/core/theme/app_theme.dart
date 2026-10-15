import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema Material 3 con la tipografía Plus Jakarta Sans y botones en píldora.
class AppTheme {
  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(
      seedColor: AppColors.primario,
      primary: AppColors.primario,
      secondary: AppColors.marino,
      tertiary: AppColors.verde,
      error: AppColors.error,
      surface: AppColors.superficie,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: esquema);
    final texto = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.marino,
      displayColor: AppColors.marino,
    );
    const pildora = StadiumBorder();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lienzo,
      textTheme: texto,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          shape: pildora,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marino,
          shape: pildora,
          side: const BorderSide(color: AppColors.borde),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primario,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Decoración de campos de formulario (píldora clara con borde azul al enfocar).
  static InputDecoration campo(String etiqueta, {String? ayuda, IconData? icono, String? sufijo}) {
    OutlineInputBorder borde(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      suffixText: sufijo,
      prefixIcon: icono == null ? null : Icon(icono, size: 20),
      filled: true,
      fillColor: AppColors.superficieAzul,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: borde(Colors.transparent),
      enabledBorder: borde(Colors.transparent),
      focusedBorder: borde(AppColors.primario, 1.6),
      errorBorder: borde(AppColors.error),
      focusedErrorBorder: borde(AppColors.error, 1.6),
    );
  }
}
