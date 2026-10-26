import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../../resenas/domain/entities/resena.dart';
import '../../../resenas/domain/usecases/resenas_usecases.dart';
import '../../../resenas/presentation/pages/resena_dialogo.dart';
import '../../../resenas/presentation/widgets/estrellas.dart';
import '../../domain/entities/cita.dart';
import '../../domain/usecases/citas_usecases.dart';
import '../cubit/citas_cubits.dart';
import '../widgets/selector_franjas.dart';
import '../widgets/tarjeta_cita.dart';

/// Detalle de una cita con las acciones permitidas según el rol y el estado.
class CitaDetallePage extends StatelessWidget {
  const CitaDetallePage({super.key, required this.citaId});
  final String citaId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CitaDetalleCubit>()..cargar(citaId),
      child: BlocBuilder<CitaDetalleCubit, Recurso<Cita>>(builder: (context, estado) {
        return switch (estado) {
          RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<CitaDetalleCubit>().cargar(citaId)),
          RecursoListo(:final datos) => _Detalle(datos),
          _ => const VistaCargando(),
        };
      }),
    );
  }
}

class _Detalle extends StatefulWidget {
  const _Detalle(this.cita);
  final Cita cita;
  @override
  State<_Detalle> createState() => _DetalleState();
}

class _DetalleState extends State<_Detalle> {
  Resena? _resena;
  bool _ocupado = false;

  Cita get c => widget.cita;
  bool get _esMedico => context.read<SesionCubit>().usuario?.esMedico ?? false;

  @override
  void initState() {
    super.initState();
    if (c.atendida) {
      sl<ObtenerResenaDeCita>()(c.id).then((r) {
        if (mounted) setState(() => _resena = r);
      }).catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(covariant _Detalle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cita.estado != c.estado && c.atendida) {
      sl<ObtenerResenaDeCita>()(c.id).then((r) {
        if (mounted) setState(() => _resena = r);
      }).catchError((_) {});
    }
  }

  Future<void> _accion(Future<void> Function() fn, String exito) async {
    setState(() => _ocupado = true);
    final error = await intentar(fn);
    if (!mounted) return;
    setState(() => _ocupado = false);
    mostrarMensaje(context, error ?? exito, error: error != null);
    if (error == null) context.read<CitaDetalleCubit>().cargar(c.id, silencioso: true);
  }

  Future<void> _cancelar() async {
    final reembolso = c.reembolsoSiCancelaAhora ?? 0;
    final ok = await confirmar(
      context,
      titulo: 'Cancelar cita',
      mensaje: _esMedico
          ? 'Al cancelar como médico se reembolsa el 100 % al paciente.'
          : 'Según la política ${c.politica.nombre.toLowerCase()}, recibirás un reembolso de ${Formatos.dinero(reembolso, c.moneda)}.',
      accion: 'Sí, cancelar',
      peligro: true,
    );
    if (!ok || !mounted) return;
    final motivo = await pedirTexto(context, titulo: 'Motivo de la cancelación', etiqueta: 'Cuéntanos brevemente el motivo', accion: 'Cancelar cita');
    if (motivo == null) return;
    setState(() => _ocupado = true);
    try {
      final (_, monto) = await sl<CancelarCita>()(c.id, motivo);
      if (!mounted) return;
      mostrarMensaje(context, 'Cita cancelada. Reembolso: ${Formatos.dinero(monto, c.moneda)}');
      context.read<CitaDetalleCubit>().cargar(c.id, silencioso: true);
    } on Failure catch (f) {
      if (mounted) mostrarMensaje(context, f.mensaje, error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _atender() async {
    final nota = TextEditingController();
    final diagnosticos = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar consulta atendida'),
        content: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nota, maxLines: 4, decoration: const InputDecoration(labelText: 'Nota clínica (se guarda cifrada en el expediente)')),
            const SizedBox(height: 10),
            TextField(controller: diagnosticos, decoration: const InputDecoration(labelText: 'Diagnósticos (separados por coma)')),
            const SizedBox(height: 10),
            const Text('El pago se liberará automáticamente en 24 h, salvo que el paciente reporte un problema.', style: TextStyle(fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Marcar atendida')),
        ],
      ),
    );
    if (ok != true) return;
    await _accion(
      () => sl<MarcarCitaAtendida>()(
        c.id,
        notaClinica: nota.text.trim(),
        diagnosticos: diagnosticos.text.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList(),
      ),
      'Consulta registrada en el expediente del paciente',
    );
  }

  Future<void> _proponerSeguimiento() async {
    final franjas = await sl<ConsultarDisponibilidad>()(c.medicoId, desde: DateTime.now().add(const Duration(days: 1)), dias: 30)
        .catchError((_) => <Franja>[]);
    if (!mounted) return;
    Franja? elegida;
    String modalidad = c.modalidad;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Proponer consulta de seguimiento'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('La cita quedará "pendiente de aceptación" hasta que la otra parte la acepte (máximo 48 h).',
                    style: TextStyle(color: AppColors.pizarra, fontSize: 13)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'VIRTUAL', label: Text('Videollamada')),
                    ButtonSegment(value: 'PRESENCIAL', label: Text('Presencial')),
                  ],
                  selected: {modalidad},
                  onSelectionChanged: (s) => setLocal(() => modalidad = s.first),
                ),
                const SizedBox(height: 12),
                SelectorFranjas(franjas: franjas, seleccionada: elegida, alElegir: (f) => setLocal(() => elegida = f)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar propuesta')),
          ],
        ),
      ),
    );
    final franja = elegida;
    if (ok != true || franja == null) return;
    await _accion(() async {
      final nueva = await sl<ProponerSeguimiento>()(PropuestaSeguimiento(
        pacienteId: c.pacienteId,
        medicoId: c.medicoId,
        inicio: franja.inicio,
        modalidad: modalidad,
        citaOrigenId: c.id,
        motivo: 'Consulta de seguimiento',
      ));
      if (mounted) context.push('/citas/${nueva.id}');
    }, 'Propuesta enviada');
  }

  @override
  Widget build(BuildContext context) {
    final esMedico = _esMedico;
    final miParte = esMedico ? 'MEDICO' : 'PACIENTE';
    final ancho = MediaQuery.sizeOf(context).width;

    final acciones = <Widget>[
      if (c.pendienteAceptacion && c.parteQueDebeResponder == miParte) ...[
        FilledButton.icon(
          onPressed: _ocupado ? null : () => _accion(() => sl<ResponderPropuesta>().aceptar(c.id), 'Propuesta aceptada: cita confirmada y pago retenido'),
          icon: const Icon(Icons.check),
          label: const Text('Aceptar propuesta'),
        ),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _accion(() => sl<ResponderPropuesta>().rechazar(c.id), 'Propuesta rechazada'),
          icon: const Icon(Icons.close),
          label: const Text('Rechazar'),
        ),
      ],
      if (c.pendienteAceptacion && c.parteQueDebeResponder != miParte)
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _accion(() => sl<ResponderPropuesta>().rechazar(c.id), 'Propuesta retirada'),
          icon: const Icon(Icons.undo),
          label: const Text('Retirar propuesta'),
        ),
      if (esMedico && c.confirmada) ...[
        FilledButton.icon(onPressed: _ocupado ? null : _atender, icon: const Icon(Icons.task_alt), label: const Text('Marcar como atendida')),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _accion(() => sl<MarcarCitaAtendida>().noAsistio(c.id), 'Inasistencia registrada'),
          icon: const Icon(Icons.person_off_outlined),
          label: const Text('No asistió'),
        ),
      ],
      if (c.confirmada && c.futura)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: _ocupado ? null : _cancelar,
          icon: const Icon(Icons.event_busy),
          label: const Text('Cancelar cita'),
        ),
      if (esMedico && (c.confirmada || c.atendida))
        FilledButton.tonalIcon(
          onPressed: () => context.push(
            '/medico/pacientes/${c.pacienteId}/historia/consulta?citaId=${c.id}&nombre=${Uri.encodeComponent(c.pacienteNombre)}',
          ),
          icon: const Icon(Icons.medical_information_outlined),
          label: const Text('Registrar historia clínica'),
        ),
      if (esMedico && c.atendida) ...[
        FilledButton.icon(onPressed: () => context.push('/citas/${c.id}/recipe', extra: c), icon: const Icon(Icons.receipt_long), label: const Text('Emitir récipe')),
        OutlinedButton.icon(
          onPressed: () => context.push('/medico/examenes/solicitar?pacienteId=${c.pacienteId}&citaId=${c.id}&nombre=${Uri.encodeComponent(c.pacienteNombre)}'),
          icon: const Icon(Icons.biotech_outlined),
          label: const Text('Solicitar exámenes'),
        ),
      ],
      if (c.atendida)
        OutlinedButton.icon(onPressed: _ocupado ? null : _proponerSeguimiento, icon: const Icon(Icons.event_repeat), label: const Text('Proponer seguimiento')),
      if (esMedico)
        TextButton.icon(
          onPressed: () => context.push('/medico/pacientes/${c.pacienteId}?nombre=${Uri.encodeComponent(c.pacienteNombre)}'),
          icon: const Icon(Icons.folder_shared_outlined),
          label: const Text('Ver expediente'),
        ),
      if (!esMedico && c.puedeReportarProblema)
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.ambar),
          onPressed: () async {
            final motivo = await pedirTexto(context, titulo: 'Reportar un problema', etiqueta: '¿Qué ocurrió con la consulta?', accion: 'Reportar');
            if (motivo == null) return;
            await _accion(() => sl<ReportarProblemaPago>()(c.id, motivo), 'Reporte enviado: el pago queda retenido hasta su revisión');
          },
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Reportar un problema'),
        ),
    ];

    final detalle = BwTarjeta(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.confirmation_number_outlined, color: AppColors.primario),
          const SizedBox(width: 8),
          Text('#${c.codigo}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const Spacer(),
          ChipEstado(c.estadoLegible, color: colorEstadoCita(c.estado)),
        ]),
        const Divider(height: 28),
        Row(children: [
          AvatarIniciales(esMedico ? c.pacienteNombre : c.medicoNombre, radio: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(esMedico ? c.pacienteNombre : c.medicoNombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              Text(esMedico ? 'Paciente' : '${c.especialidad} · paciente: ${c.pacienteNombre}', style: const TextStyle(color: AppColors.pizarra)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        FilaDato('Fecha', Formatos.fechaLarga(c.inicio), icono: Icons.calendar_today_outlined),
        FilaDato('Hora', '${Formatos.hora(c.inicio)} – ${Formatos.hora(c.fin)}', icono: Icons.schedule),
        FilaDato('Modalidad', c.esVirtual ? 'Videollamada' : 'Presencial${c.direccion != null ? ' · ${c.direccion}' : ''}', icono: Icons.place_outlined),
        if (c.motivo.isNotEmpty) FilaDato('Motivo', c.motivo, icono: Icons.notes),
        if (c.pendienteAceptacion && c.propuestaExpiraEn != null)
          FilaDato('Responder antes de', Formatos.fechaHora(c.propuestaExpiraEn!), icono: Icons.timer_outlined),
        if (c.motivoCancelacion != null)
          FilaDato('Cancelada por ${c.canceladaPor?.toLowerCase() ?? ''}', c.motivoCancelacion!, icono: Icons.info_outline),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: acciones),
      ]),
    );

    final lateral = Column(children: [
      SeccionTarjeta(
        titulo: 'Pago',
        icono: Icons.payments_outlined,
        child: Column(children: [
          FilaDato('Total', Formatos.dinero(c.monto, c.moneda), destacado: true),
          if (c.pago != null) ...[
            FilaDato('Estado', c.pago!.descripcion),
            if (c.pago!.montoReembolsado > 0) FilaDato('Reembolsado', Formatos.dinero(c.pago!.montoReembolsado, c.moneda)),
            if (c.pago!.estado == 'RETENIDO' && c.pago!.liberarDespuesDe != null)
              FilaDato('Se libera al médico', Formatos.fechaHora(c.pago!.liberarDespuesDe!)),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: 'Política ${c.politica.nombre.toLowerCase()}',
        subtitulo: 'Aceptada al reservar',
        icono: Icons.policy_outlined,
        child: Text(c.politica.descripcion, style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
      ),
      if (c.atendida && !esMedico) ...[
        const SizedBox(height: 16),
        SeccionTarjeta(
          titulo: 'Tu reseña',
          icono: Icons.reviews_outlined,
          child: _resena == null
              ? FilledButton.icon(
                  onPressed: () async {
                    if (await mostrarDialogoResena(context, citaId: c.id)) {
                      final r = await sl<ObtenerResenaDeCita>()(c.id);
                      if (mounted) setState(() => _resena = r);
                    }
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Calificar consulta'),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Estrellas(_resena!.promedio),
                  if (_resena!.comentario != null) Text('“${_resena!.comentario}”', style: const TextStyle(fontStyle: FontStyle.italic)),
                  if (_resena!.editable)
                    TextButton(
                      onPressed: () async {
                        if (await mostrarDialogoResena(context, citaId: c.id, existente: _resena)) {
                          final r = await sl<ObtenerResenaDeCita>()(c.id);
                          if (mounted) setState(() => _resena = r);
                        }
                      },
                      child: const Text('Editar (disponible 7 días)'),
                    ),
                ]),
        ),
      ],
    ]);

    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Encabezado(antetitulo: 'Detalle de la cita', titulo: 'Consulta médica'),
          if (ancho >= 1000)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: detalle),
              const SizedBox(width: 24),
              SizedBox(width: 340, child: lateral),
            ])
          else ...[
            detalle,
            const SizedBox(height: 16),
            lateral,
          ],
        ]),
      ),
    );
  }
}
