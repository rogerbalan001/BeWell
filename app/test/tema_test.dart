import 'dart:math' as math;

import 'package:bewell/core/theme/app_colors.dart';
import 'package:bewell/core/widgets/bw_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG 2.1 entre dos colores opacos.
double contraste(Color a, Color b) {
  double canal(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminancia(Color c) => 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  final la = luminancia(a), lb = luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Color de fondo de un chip: el color con alfa 28 sobre blanco.
Color tinte(Color c) => Color.alphaBlend(c.withAlpha(28), Colors.white);

void main() {
  group('Contraste mínimo 4.5:1 (criterio de la HU de interfaz coherente)', () {
    final fondos = {'blanco': Colors.white, 'lienzo': AppColors.lienzo, 'superficieAzul': AppColors.superficieAzul, 'superficieAzul2': AppColors.superficieAzul2};
    for (final texto in {'marino': AppColors.marino, 'pizarra': AppColors.pizarra, 'pizarraClara': AppColors.pizarraClara}.entries) {
      for (final fondo in fondos.entries) {
        test('${texto.key} sobre ${fondo.key}', () => expect(contraste(texto.value, fondo.value), greaterThanOrEqualTo(4.5)));
      }
    }

    test('texto blanco sobre el azul primario', () => expect(contraste(AppColors.sobrePrimario, AppColors.primario), greaterThanOrEqualTo(4.5)));

    for (final c in {'verde': AppColors.verde, 'primario': AppColors.primario, 'ámbar': AppColors.ambar, 'error': AppColors.error, 'pizarraClara': AppColors.pizarraClara}.entries) {
      test('texto de un chip ${c.key} sobre su fondo teñido', () {
        expect(contraste(AppColors.textoSobreTinte(c.value), tinte(c.value)), greaterThanOrEqualTo(4.5));
      });
    }
  });

  testWidgets('ChipEstado usa la versión legible del color para el texto', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ChipEstado('Confirmada'))));
    final texto = tester.widget<Text>(find.text('Confirmada'));
    expect(texto.style?.color, AppColors.verdeOscuro);
  });
}
