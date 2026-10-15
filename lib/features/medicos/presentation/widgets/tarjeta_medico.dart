import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../resenas/presentation/widgets/estrellas.dart';
import '../../domain/entities/medico.dart';

/// Tarjeta del directorio (diseño "Directorio de especialistas").
class TarjetaMedico extends StatelessWidget {
  const TarjetaMedico({super.key, required this.medico, required this.alSeleccionar, this.alVerPerfil});
  final Medico medico;
  final VoidCallback alSeleccionar;
  final VoidCallback? alVerPerfil;

  @override
  Widget build(BuildContext context) {
    final angosto = MediaQuery.sizeOf(context).width < 640;
    final cabecera = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AvatarIniciales(medico.nombreCompleto, radio: angosto ? 28 : 36, verificado: medico.verificado),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (medico.verificado) const ChipEstado('Médico verificado', icono: Icons.verified_rounded),
            if (medico.ofreceVirtual)
              const ChipEstado('Teleconsulta', icono: Icons.videocam_outlined, color: AppColors.primario),
          ]),
          const SizedBox(height: 8),
          Text(medico.nombreCompleto, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          Text(medico.especialidad, style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            Estrellas(medico.calificacion, tamano: 15),
            const SizedBox(width: 6),
            Text(
              medico.totalResenas == 0 ? 'Sin reseñas aún' : '${medico.calificacion.toStringAsFixed(1)} (${medico.totalResenas} reseñas)',
              style: const TextStyle(color: AppColors.pizarra, fontSize: 13),
            ),
          ]),
          if (medico.direccion != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.apartment_outlined, size: 16, color: AppColors.pizarraClara),
              const SizedBox(width: 6),
              Expanded(child: Text(medico.direccion!, style: const TextStyle(color: AppColors.pizarra, fontSize: 13))),
            ]),
          ],
        ]),
      ),
    ]);

    final pie = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(18)),
      child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 10, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Consulta', style: TextStyle(fontSize: 12, color: AppColors.pizarra)),
          Text(Formatos.dinero(medico.tarifa, medico.moneda), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Política ${medico.politica.nombre.toLowerCase()}', style: const TextStyle(fontSize: 12, color: AppColors.pizarraClara)),
        ]),
        Wrap(spacing: 8, children: [
          if (alVerPerfil != null) OutlinedButton(onPressed: alVerPerfil, child: const Text('Ver perfil')),
          FilledButton.icon(
            onPressed: medico.tieneHorario ? alSeleccionar : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(medico.tieneHorario ? 'Seleccionar y ver horarios' : 'Sin horario publicado'),
          ),
        ]),
      ]),
    );

    return BwTarjeta(child: Column(children: [cabecera, const SizedBox(height: 16), pie]));
  }
}
