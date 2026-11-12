import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema Material 3 de Bewell.
///
/// Tipografía en dos voces, como un prospecto médico bien hecho:
/// - Hanken Grotesk para títulos y cifras: firme, compacta, con carácter.
/// - Atkinson Hyperlegible para el texto de lectura y los controles: diseñada
///   por el Braille Institute para lectores con baja visión, distingue sin
///   ambigüedad 1/l/I y 0/O, algo que importa en dosis, códigos y fechas.
class AppTheme {
  /// Estilo de títulos (Hanken Grotesk) para usar fuera del `TextTheme`.
  static TextStyle titulos({double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height, Color? color}) =>
      GoogleFonts.hankenGrotesk(fontSize: fontSize, fontWeight: fontWeight, letterSpacing: letterSpacing, height: height, color: color);

  static TextTheme _escala() {
    TextStyle t(double size, FontWeight w, {double ls = 0, double h = 1.2}) =>
        GoogleFonts.hankenGrotesk(fontSize: size, fontWeight: w, letterSpacing: ls, height: h, color: AppColors.marino);
    TextStyle c(double size, FontWeight w, {double h = 1.5, Color color = AppColors.marino}) =>
        GoogleFonts.atkinsonHyperlegible(fontSize: size, fontWeight: w, height: h, color: color);

    // Escala modular ~1.2 (tercera menor) a partir de 16 px.
    return TextTheme(
      displayLarge: t(56, FontWeight.w800, ls: -1.8, h: 1.04),
      displayMedium: t(44, FontWeight.w800, ls: -1.3, h: 1.06),
      displaySmall: t(36, FontWeight.w800, ls: -1.0, h: 1.1),
      headlineLarge: t(32, FontWeight.w800, ls: -0.8, h: 1.12),
      headlineMedium: t(28, FontWeight.w800, ls: -0.6, h: 1.15),
      headlineSmall: t(23, FontWeight.w700, ls: -0.4, h: 1.2),
      titleLarge: t(20, FontWeight.w700, ls: -0.2, h: 1.25),
      titleMedium: t(17, FontWeight.w700, ls: -0.1, h: 1.3),
      titleSmall: t(15, FontWeight.w700, h: 1.3),
      bodyLarge: c(16.5, FontWeight.w400, h: 1.6, color: AppColors.pizarra),
      bodyMedium: c(15, FontWeight.w400),
      bodySmall: c(13, FontWeight.w400, color: AppColors.pizarraClara),
      labelLarge: c(14.5, FontWeight.w700, h: 1.3),
      labelMedium: c(13, FontWeight.w700, h: 1.3),
      labelSmall: c(12, FontWeight.w700, h: 1.3),
    );
  }

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
    final texto = _escala();
    final etiqueta = GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w700, fontSize: 15, height: 1.2);
    const pildora = StadiumBorder();
    // Respuesta táctil inmediata y discreta: el botón se oscurece al presionar
    // en lugar de expandir una onda que tarda en asentarse.
    const sinOnda = NoSplash.splashFactory;

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lienzo,
      textTheme: texto,
      primaryTextTheme: texto,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(color: AppColors.borde, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.marino,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borde)),
        // Sin color propio: lo hereda de foregroundColor de cada barra.
        titleTextStyle: GoogleFonts.hankenGrotesk(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.superficieAzul2,
          shape: pildora,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: etiqueta,
          splashFactory: sinOnda,
          animationDuration: const Duration(milliseconds: 120),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.pressed)) return Colors.black.withAlpha(36);
            if (s.contains(WidgetState.hovered)) return Colors.black.withAlpha(18);
            if (s.contains(WidgetState.focused)) return Colors.white.withAlpha(30);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marino,
          shape: pildora,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.bordeFuerte),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: etiqueta.copyWith(fontSize: 14.5),
          splashFactory: sinOnda,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primarioOscuro,
          minimumSize: const Size(48, 44),
          textStyle: etiqueta.copyWith(fontSize: 14.5),
          splashFactory: sinOnda,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: etiqueta.copyWith(fontSize: 14),
          selectedBackgroundColor: AppColors.superficieAzul2,
          selectedForegroundColor: AppColors.primarioOscuro,
          side: const BorderSide(color: AppColors.bordeFuerte),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(labelStyle: texto.labelMedium, side: const BorderSide(color: AppColors.borde)),
      listTileTheme: ListTileThemeData(titleTextStyle: texto.titleSmall, subtitleTextStyle: texto.bodySmall?.copyWith(color: AppColors.pizarra)),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: texto.titleLarge,
        contentTextStyle: texto.bodyMedium?.copyWith(color: AppColors.pizarra),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: GoogleFonts.atkinsonHyperlegible(color: Colors.white, fontSize: 14.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.atkinsonHyperlegible(color: Colors.white, fontSize: 13),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }

  /// Decoración de campos de formulario (campo claro con borde azul al enfocar).
  static InputDecoration campo(String etiqueta, {String? ayuda, IconData? icono, String? sufijo}) {
    OutlineInputBorder borde(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      suffixText: sufijo,
      prefixIcon: icono == null ? null : Icon(icono, size: 20),
      filled: true,
      fillColor: AppColors.superficieAzul,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: borde(Colors.transparent),
      enabledBorder: borde(AppColors.bordeAzul),
      focusedBorder: borde(AppColors.primario, 2),
      errorBorder: borde(AppColors.error),
      focusedErrorBorder: borde(AppColors.error, 2),
    );
  }
}
