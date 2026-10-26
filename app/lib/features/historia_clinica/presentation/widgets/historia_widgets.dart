import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/historia_clinica.dart';

/// Bloque "título + viñetas" de un grupo de antecedentes.
class GrupoAntecedentes extends StatelessWidget {
  const GrupoAntecedentes({super.key, required this.titulo, required this.icono, required this.valores, this.color = AppColors.primario});
  final String titulo;
  final IconData icono;
  final List<String> valores;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 6),
      if (valores.isEmpty)
        const Text('Niega / no registrado', style: TextStyle(color: AppColors.pizarraClara, fontSize: 13))
      else
        for (final v in valores)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: color)),
              const SizedBox(width: 8),
              Expanded(child: Text(v, style: const TextStyle(fontSize: 14))),
            ]),
          ),
    ]);
  }
}

/// Tarjeta expandible con la historia de una consulta.
class TarjetaConsulta extends StatelessWidget {
  const TarjetaConsulta({super.key, required this.consulta, this.alCorregir});
  final ConsultaClinica consulta;
  final VoidCallback? alCorregir;

  @override
  Widget build(BuildContext context) {
    final c = consulta.contenido;
    final medico = consulta.medico;
    Widget seccion(String titulo, String? texto) => (texto == null || texto.trim().isEmpty)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo.toUpperCase(), style: const TextStyle(color: AppColors.primario, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(texto, style: const TextStyle(height: 1.45)),
            ]),
          );

    return BwTarjeta(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medical_information_outlined, color: AppColors.primario, size: 20),
          ),
          title: Text(c.motivoConsulta, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            [Formatos.fechaCorta(consulta.fecha), if (medico != null) '${medico.nombreCompleto} · ${medico.especialidad}'].join(' · '),
            style: const TextStyle(color: AppColors.pizarra, fontSize: 13),
          ),
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final d in c.impresionDiagnostica) ChipEstado(d, color: AppColors.marino, fondo: AppColors.superficieAzul2, icono: Icons.local_hospital_outlined),
            ]),
            if (!c.signosVitales.vacio) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final s in c.signosVitales.resumen) ChipEstado(s, color: AppColors.verdeOscuro, icono: Icons.monitor_heart_outlined),
              ]),
            ],
            seccion('Enfermedad actual', c.enfermedadActual),
            seccion('Revisión por sistemas', c.revisionPorSistemas),
            seccion('Examen físico', c.examenFisico),
            seccion('Plan', c.plan),
            seccion('Indicaciones', c.indicaciones),
            if (alCorregir != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(onPressed: alCorregir, icon: const Icon(Icons.edit_outlined), label: const Text('Corregir (24 h)')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Editor de una lista de textos: chips eliminables + campo para agregar.
class EditorLista extends StatefulWidget {
  const EditorLista({super.key, required this.etiqueta, required this.valores, required this.alCambiar, this.ayuda});
  final String etiqueta;
  final List<String> valores;
  final ValueChanged<List<String>> alCambiar;
  final String? ayuda;

  @override
  State<EditorLista> createState() => _EditorListaState();
}

class _EditorListaState extends State<EditorLista> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _agregar() {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    if (!widget.valores.contains(texto)) widget.alCambiar([...widget.valores, texto]);
    _controlador.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _controlador,
        onSubmitted: (_) => _agregar(),
        decoration: AppTheme.campo(widget.etiqueta, ayuda: widget.ayuda).copyWith(
          suffixIcon: IconButton(tooltip: 'Agregar', icon: const Icon(Icons.add_circle_outline), onPressed: _agregar),
        ),
      ),
      if (widget.valores.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in widget.valores)
            InputChip(
              label: Text(v),
              onDeleted: () => widget.alCambiar(widget.valores.where((x) => x != v).toList()),
            ),
        ]),
      ],
    ]);
  }
}
