import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/expediente.dart';

IconData iconoEvento(String tipo) => switch (tipo) {
      'CONSULTA' => Icons.medical_services_outlined,
      'DIAGNOSTICO' => Icons.monitor_heart_outlined,
      'CIRUGIA' => Icons.healing_outlined,
      'VACUNA' => Icons.vaccines_outlined,
      'EXAMEN' => Icons.biotech_outlined,
      'SOLICITUD_EXAMEN' => Icons.assignment_outlined,
      'RECETA' => Icons.receipt_long_outlined,
      'REFERENCIA' => Icons.forward_to_inbox_outlined,
      _ => Icons.psychology_outlined,
    };

/// Línea de tiempo del paciente (del evento más reciente al más antiguo).
class LineaTiempo extends StatelessWidget {
  const LineaTiempo({super.key, required this.eventos});
  final List<EventoClinico> eventos;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < eventos.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 44,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.primario, shape: BoxShape.circle),
                  child: Icon(iconoEvento(eventos[i].tipo), color: Colors.white, size: 18),
                ),
                if (i < eventos.length - 1) Expanded(child: Container(width: 2, color: AppColors.superficieAzul2)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BwTarjeta(
                  padding: const EdgeInsets.all(18),
                  onTap: () => _detalle(context, eventos[i]),
                  child: _Evento(eventos[i]),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }

  void _detalle(BuildContext context, EventoClinico e) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ChipEstado(e.tipoLegible, color: AppColors.primario, icono: iconoEvento(e.tipo)),
            const SizedBox(height: 10),
            Text(e.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(Formatos.fechaHora(e.fecha), style: const TextStyle(color: AppColors.pizarra)),
            if (e.medico != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                AvatarIniciales(e.medico!.nombreCompleto, radio: 18, verificado: e.medico!.verificado),
                const SizedBox(width: 10),
                Text('${e.medico!.nombreCompleto} · ${e.medico!.especialidad}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ],
            const Divider(height: 28),
            Text(e.resumen.isEmpty ? 'Sin detalle adicional.' : e.resumen, style: const TextStyle(height: 1.6)),
            if (e.detalles.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final d in e.detalles.entries.where((x) => x.key != 'autoReportado')) FilaDato(d.key, d.value),
            ],
            if (e.autoReportado) ...[
              const SizedBox(height: 12),
              const ChipEstado('Dato registrado por el paciente', color: AppColors.ambar, icono: Icons.person_outline),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Evento extends StatelessWidget {
  const _Evento(this.e);
  final EventoClinico e;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        ChipEstado(e.tipoLegible, color: AppColors.primario, fondo: AppColors.superficieAzul2),
        Text(Formatos.fechaHora(e.fecha), style: const TextStyle(color: AppColors.pizarra, fontSize: 12.5)),
        if (e.autoReportado) const ChipEstado('Auto-reportado', color: AppColors.ambar),
      ]),
      const SizedBox(height: 8),
      Text(e.titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      if (e.medico != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('${e.medico!.nombreCompleto} · ${e.medico!.especialidad}', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
        ),
      if (e.resumen.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(e.resumen, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.pizarra, height: 1.5)),
      ],
      const SizedBox(height: 6),
      const Text('Ver detalle clínico completo →', style: TextStyle(color: AppColors.primario, fontSize: 12.5, fontWeight: FontWeight.w600)),
    ]);
  }
}
