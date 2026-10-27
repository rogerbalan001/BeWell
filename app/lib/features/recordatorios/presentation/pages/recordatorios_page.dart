import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/recordatorio.dart';
import '../cubit/recordatorios_cubit.dart';

IconData _icono(TipoRecordatorio t) => switch (t) {
      TipoRecordatorio.citas => Icons.event_note_outlined,
      TipoRecordatorio.medicamentos => Icons.medication_outlined,
      TipoRecordatorio.examenes => Icons.biotech_outlined,
    };

/// HU-5: recordatorios de citas, medicamentos y exámenes.
class RecordatoriosPage extends StatelessWidget {
  const RecordatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<RecordatoriosCubit>()..cargar(), child: const _Vista());
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  Future<void> _cambiar(BuildContext context, TipoRecordatorio tipo, bool activo) async {
    final error = await context.read<RecordatoriosCubit>().cambiar(tipo, activo);
    if (!context.mounted) return;
    mostrarMensaje(
      context,
      error ?? (activo ? 'Recordatorios de ${tipo.titulo.toLowerCase()} activados' : 'Ya no te recordaremos ${tipo.titulo.toLowerCase()}'),
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordatoriosCubit, Recurso<DatosRecordatorios>>(builder: (context, estado) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 860,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Encabezado(
              antetitulo: 'Tu tratamiento al día',
              titulo: 'Recordatorios',
              descripcion: 'Te avisamos de tus citas, tus medicamentos y los exámenes pendientes, también los de tu familia. '
                  'Los recibes en Notificaciones.',
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<RecordatoriosCubit>().cargar()),
              RecursoListo(:final datos) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SeccionTarjeta(
                    titulo: 'Qué te recordamos',
                    icono: Icons.tune,
                    child: Column(children: [
                      for (final tipo in TipoRecordatorio.values)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(_icono(tipo), color: AppColors.primario),
                          title: Text(tipo.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(tipo.descripcion, style: const TextStyle(fontSize: 13, color: AppColors.pizarra)),
                          value: datos.preferencias.permite(tipo),
                          onChanged: (v) => _cambiar(context, tipo, v),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SeccionTarjeta(
                    titulo: 'Próximos 7 días',
                    icono: Icons.notifications_active_outlined,
                    child: datos.proximos.isEmpty
                        ? const VistaVacia(
                            icono: Icons.notifications_off_outlined,
                            titulo: 'No hay recordatorios en los próximos días',
                            mensaje: 'Aparecerán cuando tengas una cita confirmada, un récipe vigente o una orden de exámenes pendiente.',
                          )
                        : Column(children: [for (final r in datos.proximos) _FilaRecordatorio(r)]),
                  ),
                ]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }
}

class _FilaRecordatorio extends StatelessWidget {
  const _FilaRecordatorio(this.r);
  final Recordatorio r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(12)),
          child: Icon(_icono(r.tipo), color: AppColors.primario, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(r.mensaje, style: const TextStyle(fontSize: 13, color: AppColors.pizarra, height: 1.4)),
            const SizedBox(height: 4),
            Text(
              Formatos.fechaHora(r.programadoPara),
              style: const TextStyle(fontSize: 12, color: AppColors.pizarraClara, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
      ]),
    );
  }
}
