import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class Estrellas extends StatelessWidget {
  const Estrellas(this.valor, {super.key, this.tamano = 16});
  final double valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          valor >= i ? Icons.star_rounded : (valor >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: tamano,
          color: AppColors.primario,
        ),
    ]);
  }
}

/// Selector de 1 a 5 estrellas.
class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({super.key, required this.etiqueta, required this.valor, required this.alCambiar});
  final String etiqueta;
  final int valor;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600))),
      for (var i = 1; i <= 5; i++)
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => alCambiar(i),
          icon: Icon(i <= valor ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.primario),
        ),
    ]);
  }
}
