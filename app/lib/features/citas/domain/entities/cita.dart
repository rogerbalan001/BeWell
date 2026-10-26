import 'package:equatable/equatable.dart';

import '../../../medicos/domain/entities/medico.dart';

class Franja extends Equatable {
  const Franja(this.inicio, this.fin);
  final DateTime inicio;
  final DateTime fin;
  @override
  List<Object?> get props => [inicio, fin];
}

class PagoResumen extends Equatable {
  const PagoResumen({required this.estado, required this.monto, required this.montoReembolsado, this.liberarDespuesDe, this.motivoDisputa});
  final String estado;
  final double monto;
  final double montoReembolsado;
  final DateTime? liberarDespuesDe;
  final String? motivoDisputa;

  String get descripcion => switch (estado) {
        'RETENIDO' => 'Pago retenido (protegido)',
        'EN_DISPUTA' => 'Retenido por reporte en revisión',
        'LIBERADO' => 'Liberado al médico',
        'REEMBOLSADO' => 'Reembolsado',
        'REEMBOLSADO_PARCIAL' => 'Reembolso parcial',
        'FALLIDO' => 'Pago rechazado',
        _ => estado,
      };

  @override
  List<Object?> get props => [estado, montoReembolsado, liberarDespuesDe];
}

/// Cita médica con su estado, la política de cancelación aplicada y el pago.
class Cita extends Equatable {
  const Cita({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.inicio,
    required this.fin,
    required this.modalidad,
    required this.motivo,
    required this.monto,
    required this.moneda,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.medicoId,
    required this.medicoNombre,
    required this.especialidad,
    required this.politica,
    this.direccion,
    this.propuestaPor,
    this.propuestaExpiraEn,
    this.parteQueDebeResponder,
    this.canceladaPor,
    this.motivoCancelacion,
    this.atendidaEn,
    this.citaOrigenId,
    this.pago,
    this.reembolsoSiCancelaAhora,
  });

  final String id;
  final String codigo;
  final String estado;
  final DateTime inicio;
  final DateTime fin;
  final String modalidad;
  final String motivo;
  final double monto;
  final String moneda;
  final String pacienteId;
  final String pacienteNombre;
  final String medicoId;
  final String medicoNombre;
  final String especialidad;
  final PoliticaCancelacion politica;
  final String? direccion;
  final String? propuestaPor;
  final DateTime? propuestaExpiraEn;
  final String? parteQueDebeResponder;
  final String? canceladaPor;
  final String? motivoCancelacion;
  final DateTime? atendidaEn;
  final String? citaOrigenId;
  final PagoResumen? pago;
  final double? reembolsoSiCancelaAhora;

  bool get esVirtual => modalidad == 'VIRTUAL';
  bool get confirmada => estado == 'CONFIRMADA';
  bool get atendida => estado == 'ATENDIDA';
  bool get pendienteAceptacion => estado == 'PENDIENTE_ACEPTACION';
  bool get activa => const ['PENDIENTE_ACEPTACION', 'PENDIENTE_PAGO', 'CONFIRMADA'].contains(estado);
  bool get futura => inicio.isAfter(DateTime.now());

  /// HU pagos: el paciente puede reportar un problema mientras el pago siga retenido (24 h).
  bool get puedeReportarProblema =>
      atendida && pago?.estado == 'RETENIDO' && (pago?.liberarDespuesDe?.isAfter(DateTime.now()) ?? false);

  String get estadoLegible => switch (estado) {
        'PENDIENTE_ACEPTACION' => 'Pendiente de aceptación',
        'PENDIENTE_PAGO' => 'Pendiente de pago',
        'CONFIRMADA' => 'Confirmada',
        'ATENDIDA' => 'Atendida',
        'CANCELADA' => 'Cancelada',
        'NO_ASISTIO' => 'No asistió',
        _ => estado,
      };

  @override
  List<Object?> get props => [id, estado, pago, inicio];
}

class SolicitudCita {
  const SolicitudCita({required this.medicoId, required this.pacienteId, required this.inicio, required this.modalidad, required this.motivo});
  final String medicoId;
  final String pacienteId;
  final DateTime inicio;
  final String modalidad;
  final String motivo;
}

class PropuestaSeguimiento {
  const PropuestaSeguimiento({required this.pacienteId, required this.inicio, required this.modalidad, this.medicoId, this.citaOrigenId, this.referenciaId, this.motivo});
  final String pacienteId;
  final String? medicoId;
  final DateTime inicio;
  final String modalidad;
  final String? citaOrigenId;
  final String? referenciaId;
  final String? motivo;
}
