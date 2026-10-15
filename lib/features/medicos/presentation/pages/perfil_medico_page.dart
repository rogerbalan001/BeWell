import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../resenas/presentation/widgets/estrellas.dart';
import '../cubit/medicos_cubits.dart';

/// Perfil público del médico con sus reseñas verificadas.
class PerfilMedicoPage extends StatelessWidget {
  const PerfilMedicoPage({super.key, required this.medicoId});
  final String medicoId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PerfilMedicoCubit>()..cargar(medicoId),
      child: BlocBuilder<PerfilMedicoCubit, Recurso<PerfilMedicoDatos>>(builder: (context, estado) {
        return switch (estado) {
          RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<PerfilMedicoCubit>().cargar(medicoId)),
          RecursoListo(:final datos) => _Contenido(datos),
          _ => const VistaCargando(),
        };
      }),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido(this.d);
  final PerfilMedicoDatos d;

  @override
  Widget build(BuildContext context) {
    final m = d.medico;
    final e = d.estadisticas;
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BwTarjeta(
            padding: const EdgeInsets.all(28),
            child: Wrap(spacing: 24, runSpacing: 20, crossAxisAlignment: WrapCrossAlignment.center, children: [
              AvatarIniciales(m.nombreCompleto, radio: 48, verificado: m.verificado),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (m.verificado) const ChipEstado('Médico verificado', icono: Icons.verified_rounded),
                  const SizedBox(height: 8),
                  Text(m.nombreCompleto, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text(m.especialidad, style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w600, fontSize: 16)),
                  if (m.biografia != null) ...[
                    const SizedBox(height: 10),
                    Text(m.biografia!, style: const TextStyle(color: AppColors.pizarra, height: 1.5)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ChipEstado(Formatos.dinero(m.tarifa, m.moneda), icono: Icons.payments_outlined, color: AppColors.marino),
                    if (m.ofrecePresencial) const ChipEstado('Presencial', icono: Icons.apartment, color: AppColors.primario),
                    if (m.ofreceVirtual) const ChipEstado('Videollamada', icono: Icons.videocam_outlined, color: AppColors.primario),
                  ]),
                ]),
              ),
              FilledButton.icon(
                onPressed: m.tieneHorario ? () => context.push('/agendar/${m.id}') : null,
                icon: const Icon(Icons.event_available),
                label: const Text('Reservar cita'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SeccionTarjeta(
            titulo: 'Política de cancelación ${m.politica.nombre.toLowerCase()}',
            icono: Icons.policy_outlined,
            child: Text(m.politica.descripcion, style: const TextStyle(color: AppColors.pizarra)),
          ),
          const SizedBox(height: 16),
          SeccionTarjeta(
            titulo: 'Experiencias de pacientes',
            subtitulo: 'Solo pacientes con consultas atendidas pueden reseñar',
            icono: Icons.reviews_outlined,
            accion: e.total == 0
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: AppColors.primario),
                    Text(' ${e.promedio.toStringAsFixed(1)} de 5', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
            child: e.total == 0
                ? const Text('Este médico aún no tiene reseñas.', style: TextStyle(color: AppColors.pizarra))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(spacing: 22, runSpacing: 8, children: [
                      for (final (n, v) in [('Puntualidad', e.puntualidad), ('Trato', e.trato), ('Claridad', e.claridad), ('Instalaciones', e.instalaciones)])
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n, style: const TextStyle(fontSize: 12, color: AppColors.pizarra)),
                          Text(v.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primario)),
                        ]),
                    ]),
                    const Divider(height: 28),
                    for (final r in d.resenas)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(20)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            AvatarIniciales(r.autor ?? 'P', radio: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(r.autor ?? 'Paciente', style: const TextStyle(fontWeight: FontWeight.w700))),
                            Estrellas(r.promedio, tamano: 14),
                          ]),
                          if (r.comentario != null) ...[
                            const SizedBox(height: 8),
                            Text('“${r.comentario}”', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.pizarra)),
                          ],
                          const SizedBox(height: 6),
                          Text('Consulta verificada · ${Formatos.fechaCorta(r.publicadaEn)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.verdeOscuro, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}
