import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/cita.dart';

Color colorEstadoCita(String estado) => switch (estado) {
      'CONFIRMADA' => AppColors.primario,
      'ATENDIDA' => AppColors.verde,
      'PENDIENTE_ACEPTACION' || 'PENDIENTE_PAGO' => AppColors.ambar,
      _ => AppColors.pizarraClara,
    };

class TarjetaCita extends StatelessWidget {
  const TarjetaCita({super.key, required this.cita, required this.vistaMedico, required this.onTap});
  final Cita cita;
  final bool vistaMedico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titulo = vistaMedico ? cita.pacienteNombre : cita.medicoNombre;
    final sub = vistaMedico ? cita.motivo.isEmpty ? 'Sin motivo indicado' : cita.motivo : cita.especialidad;
    return BwTarjeta(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(Formatos.diaSemanaCorto(cita.inicio), style: const TextStyle(fontSize: 11, color: AppColors.pizarra)),
            Text('${cita.inicio.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(Formatos.hora(cita.inicio), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              ChipEstado(cita.estadoLegible, color: colorEstadoCita(cita.estado)),
              ChipEstado(cita.esVirtual ? 'Videollamada' : 'Presencial',
                  icono: cita.esVirtual ? Icons.videocam_outlined : Icons.apartment, color: AppColors.pizarra),
              if (!vistaMedico && cita.pacienteNombre.isNotEmpty)
                ChipEstado(cita.pacienteNombre, icono: Icons.person_outline, color: AppColors.marino),
            ]),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.pizarraClara),
      ]),
    );
  }
}
