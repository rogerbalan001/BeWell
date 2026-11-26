import 'package:flutter/material.dart';

import '../../../../core/clinico/terminologia.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_textos.dart';
import '../../domain/entities/examen.dart';

/// Tabla compacta de analitos con el nivel de confianza del OCR.
class TablaResultados extends StatelessWidget {
  const TablaResultados({super.key, required this.resultados});
  final List<ResultadoAnalito> resultados;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(children: [
        for (final r in resultados)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Expanded(flex: 3, child: Text(r.analito, style: AppTextos.enfasisSuave)),
              Expanded(flex: 2, child: _Valor(r)),
              Expanded(flex: 2, child: Text(r.rangoReferencia ?? '', style: AppTextos.detalle)),
              if (r.validadoPorMedico)
                const Tooltip(message: 'Validado por médico', child: Icon(Icons.verified, color: AppColors.verde, size: 18))
              else if (r.confianzaOcr != null)
                Tooltip(
                  message: 'Confianza del OCR',
                  child: Text('${(r.confianzaOcr! * 100).round()} %',
                      style: TextStyle(fontSize: 12, color: r.confianzaOcr! < 0.85 ? AppColors.ambar : AppColors.verdeOscuro)),
                ),
            ]),
          ),
      ]),
    );
  }
}

/// Valor con su unidad oficial y una marca cuando cae fuera del rango de referencia.
class _Valor extends StatelessWidget {
  const _Valor(this.r);
  final ResultadoAnalito r;

  @override
  Widget build(BuildContext context) {
    final posicion = posicionEnRango(r.valor, r.rangoReferencia) ?? 0;
    final fuera = posicion != 0;
    final color = fuera ? AppColors.error : null;
    return Row(children: [
      Flexible(child: Text('${r.valor} ${r.unidad ?? ''}', style: TextStyle(fontWeight: FontWeight.w800, color: color))),
      if (fuera)
        Tooltip(
          message: posicion > 0 ? 'Por encima del rango de referencia' : 'Por debajo del rango de referencia',
          child: Icon(posicion > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: AppColors.error),
        ),
    ]);
  }
}
