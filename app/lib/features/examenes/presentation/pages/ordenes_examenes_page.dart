import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';
import '../cubit/examenes_cubit.dart';

/// HU médico: ver si las órdenes de exámenes del paciente siguen pendientes,
/// ya tienen resultados (completadas) o fueron anuladas, y anular una pendiente.
class OrdenesExamenesPage extends StatelessWidget {
  const OrdenesExamenesPage({super.key, required this.pacienteId, this.pacienteNombre});
  final String pacienteId;
  final String? pacienteNombre;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdenesExamenesCubit>()..cargar(pacienteId),
      child: _Vista(pacienteId: pacienteId, pacienteNombre: pacienteNombre),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.pacienteId, this.pacienteNombre});
  final String pacienteId;
  final String? pacienteNombre;

  Future<void> _nuevaOrden(BuildContext context) async {
    final nombre = Uri.encodeComponent(pacienteNombre ?? '');
    await context.push('/medico/examenes/solicitar?pacienteId=$pacienteId&nombre=$nombre');
    if (context.mounted) context.read<OrdenesExamenesCubit>().cargar(pacienteId, silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdenesExamenesCubit, Recurso<List<SolicitudExamen>>>(builder: (context, estado) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 860,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Encabezado(
              antetitulo: 'Órdenes médicas',
              titulo: 'Exámenes indicados',
              descripcion: pacienteNombre == null || pacienteNombre!.isEmpty ? null : 'Paciente: $pacienteNombre',
              accion: FilledButton.icon(onPressed: () => _nuevaOrden(context), icon: const Icon(Icons.add), label: const Text('Nueva orden')),
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<OrdenesExamenesCubit>().cargar(pacienteId)),
              RecursoListo(:final datos) when datos.isEmpty => const VistaVacia(
                  icono: Icons.biotech_outlined,
                  titulo: 'Aún no has indicado exámenes a este paciente',
                  mensaje: 'Las órdenes que generes aparecerán aquí con su estado.',
                ),
              RecursoListo(:final datos) => Column(children: [for (final s in datos) _TarjetaOrden(s)]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }
}

class _TarjetaOrden extends StatelessWidget {
  const _TarjetaOrden(this.orden);
  final SolicitudExamen orden;

  (Color, Color, IconData) get _estilo => switch (orden.estado) {
        'COMPLETADA' => (AppColors.verdeOscuro, AppColors.verdeSuave, Icons.check_circle_outline),
        'ANULADA' => (AppColors.pizarraClara, AppColors.lienzo, Icons.block),
        _ => (AppColors.ambar, AppColors.ambarSuave, Icons.hourglass_top),
      };

  Future<void> _anular(BuildContext context) async {
    final motivo = await showDialog<String>(context: context, builder: (_) => _DialogoAnular(orden: orden));
    if (motivo == null || !context.mounted) return;
    final error = await context.read<OrdenesExamenesCubit>().anular(orden.id, motivo);
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Orden anulada. Le avisamos al paciente.', error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    final (color, fondo, icono) = _estilo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8, children: [
            Text('Indicada el ${Formatos.fechaCorta(orden.creadaEn)}', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
            ChipEstado(orden.estadoLegible, color: color, fondo: fondo, icono: icono),
          ]),
          const SizedBox(height: 8),
          Text(orden.examenes.join(' · '), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          if (orden.indicaciones.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Indicaciones: ${orden.indicaciones}', style: const TextStyle(fontSize: 13, color: AppColors.pizarra)),
          ],
          if (orden.completada) ...[
            const SizedBox(height: 8),
            Text(
              '${orden.examenResultadoIds.length == 1 ? '1 resultado cargado' : '${orden.examenResultadoIds.length} resultados cargados'}'
              '${orden.completadaEn != null ? ' · ${Formatos.fechaCorta(orden.completadaEn!)}' : ''}. Los ves en la línea de tiempo del expediente.',
              style: const TextStyle(fontSize: 13, color: AppColors.verdeOscuro),
            ),
          ],
          if (orden.anulada && (orden.motivoAnulacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Motivo de la anulación: ${orden.motivoAnulacion}', style: const TextStyle(fontSize: 13, color: AppColors.pizarra)),
          ],
          if (orden.pendiente) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _anular(context),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Anular orden'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Pide el motivo antes de anular; el paciente lo verá en su notificación.
class _DialogoAnular extends StatefulWidget {
  const _DialogoAnular({required this.orden});
  final SolicitudExamen orden;

  @override
  State<_DialogoAnular> createState() => _DialogoAnularState();
}

class _DialogoAnularState extends State<_DialogoAnular> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  bool get _valido => _motivo.text.trim().length >= GestionarOrdenesExamen.motivoMinimo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anular orden de exámenes'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.orden.examenes.join(', '), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            autofocus: true,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: AppTheme.campo('Motivo', ayuda: 'El paciente lo verá en su notificación'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volver')),
        FilledButton(
          onPressed: _valido ? () => Navigator.of(context).pop(_motivo.text.trim()) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Anular'),
        ),
      ],
    );
  }
}
