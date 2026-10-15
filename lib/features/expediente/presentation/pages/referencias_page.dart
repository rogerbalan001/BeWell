import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../../citas/domain/entities/cita.dart';
import '../../../citas/domain/usecases/citas_usecases.dart';
import '../../../citas/presentation/widgets/selector_franjas.dart';
import '../../domain/entities/expediente.dart';
import '../cubit/expediente_cubits.dart';

/// Referencias a especialistas: el paciente aprueba; el especialista propone horarios.
class ReferenciasPage extends StatelessWidget {
  const ReferenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<SesionCubit>().usuario;
    return BlocProvider(
      create: (_) => sl<ReferenciasCubit>()..cargar(),
      child: BlocBuilder<ReferenciasCubit, Recurso<List<Referencia>>>(builder: (context, estado) {
        final cubit = context.read<ReferenciasCubit>();
        return SingleChildScrollView(
          child: ContenidoCentrado(
            maxAncho: 900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Encabezado(
                antetitulo: 'Continuidad de la atención',
                titulo: 'Referencias a especialistas',
                descripcion: usuario?.esMedico ?? false
                    ? 'Referencias que enviaste y recibiste. Cuando el paciente aprueba, el especialista accede al expediente por 90 días.'
                    : 'Tu médico propone referirte a un especialista. Si apruebas, compartes tu expediente con él.',
              ),
              switch (estado) {
                RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.cargar),
                RecursoListo(:final datos) when datos.isEmpty => const VistaVacia(icono: Icons.forward_to_inbox_outlined, titulo: 'No hay referencias'),
                RecursoListo(:final datos) => Column(children: [for (final r in datos) _TarjetaReferencia(r, medicoId: usuario?.medicoId)]),
                _ => const VistaCargando(),
              },
            ]),
          ),
        );
      }),
    );
  }
}

class _TarjetaReferencia extends StatelessWidget {
  const _TarjetaReferencia(this.r, {this.medicoId});
  final Referencia r;
  final String? medicoId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReferenciasCubit>();
    final soyDestino = medicoId != null && r.medicoDestino?.id == medicoId;
    final esPaciente = medicoId == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('${r.pacienteNombre} → ${r.especialidadDestino}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ChipEstado(r.estadoLegible, color: r.pendiente ? AppColors.ambar : (r.estado == 'APROBADA' ? AppColors.verde : AppColors.pizarraClara)),
          ]),
          const SizedBox(height: 8),
          FilaDato('Refiere', r.medicoOrigen?.nombreCompleto ?? '—'),
          FilaDato('Especialista', r.medicoDestino?.nombreCompleto ?? '—'),
          FilaDato('Fecha', Formatos.fechaCorta(r.fecha)),
          const SizedBox(height: 6),
          Text('“${r.motivo}”', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.pizarra)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            if (esPaciente && r.pendiente) ...[
              FilledButton.icon(
                onPressed: () async {
                  final ok = await confirmar(context,
                      titulo: 'Compartir expediente',
                      mensaje: '${r.medicoDestino?.nombreCompleto ?? 'El especialista'} podrá ver tu expediente durante 90 días (sin la sección de salud mental).');
                  if (!ok) return;
                  final error = await intentar(() => cubit.gestion.aprobar(r.id));
                  if (!context.mounted) return;
                  mostrarMensaje(context, error ?? 'Referencia aprobada; el especialista fue notificado', error: error != null);
                  cubit.cargar(silencioso: true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Aprobar y compartir'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final error = await intentar(() => cubit.gestion.rechazar(r.id));
                  if (!context.mounted) return;
                  mostrarMensaje(context, error ?? 'Referencia rechazada', error: error != null);
                  cubit.cargar(silencioso: true);
                },
                child: const Text('Rechazar'),
              ),
            ],
            if (soyDestino && r.estado == 'APROBADA')
              FilledButton.icon(onPressed: () => _proponerHorario(context), icon: const Icon(Icons.event), label: const Text('Proponer horario de cita')),
          ]),
        ]),
      ),
    );
  }

  Future<void> _proponerHorario(BuildContext context) async {
    final franjas = await sl<ConsultarDisponibilidad>()(medicoId!, dias: 21).catchError((_) => <Franja>[]);
    if (!context.mounted) return;
    Franja? elegida;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Proponer cita a ${r.pacienteNombre}'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(child: SelectorFranjas(franjas: franjas, seleccionada: elegida, alElegir: (f) => setLocal(() => elegida = f))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar propuesta')),
          ],
        ),
      ),
    );
    final franja = elegida;
    if (ok != true || franja == null || !context.mounted) return;
    final error = await intentar(() => sl<ProponerSeguimiento>()(PropuestaSeguimiento(
          pacienteId: r.pacienteId,
          inicio: franja.inicio,
          modalidad: 'PRESENCIAL',
          referenciaId: r.id,
          motivo: 'Evaluación por referencia: ${r.especialidadDestino}',
        )));
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Propuesta enviada; el paciente tiene 48 h para aceptarla', error: error != null);
  }
}
