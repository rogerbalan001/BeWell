import 'package:equatable/equatable.dart';

/// Decisión del administrador sobre una disputa de pago.
enum AccionDisputa {
  /// El dinero retenido se entrega al médico.
  liberar('LIBERAR'),

  /// El dinero retenido vuelve al paciente.
  reembolsar('REEMBOLSAR');

  const AccionDisputa(this.codigo);

  /// Valor que espera la API.
  final String codigo;
}

/// Pago retenido porque el paciente reportó un problema con la consulta.
class Disputa extends Equatable {
  const Disputa({
    required this.pagoId,
    required this.citaId,
    required this.monto,
    required this.moneda,
    required this.estado,
    required this.motivo,
    required this.pacienteNombre,
    required this.medicoNombre,
    this.abiertaEn,
  });

  final String pagoId;
  final String citaId;
  final double monto;
  final String moneda;

  /// EN_DISPUTA mientras está abierta; LIBERADO o REEMBOLSADO al resolverse.
  final String estado;

  /// Lo que el paciente escribió al reportar el problema.
  final String motivo;
  final String pacienteNombre;
  final String medicoNombre;
  final DateTime? abiertaEn;

  bool get abierta => estado == 'EN_DISPUTA';

  @override
  List<Object?> get props => [pagoId, estado];
}
