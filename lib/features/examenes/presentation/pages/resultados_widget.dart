import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
              Expanded(flex: 3, child: Text(r.analito, style: const TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('${r.valor} ${r.unidad ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800))),
              Expanded(flex: 2, child: Text(r.rangoReferencia ?? '', style: const TextStyle(color: AppColors.pizarra, fontSize: 12))),
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
