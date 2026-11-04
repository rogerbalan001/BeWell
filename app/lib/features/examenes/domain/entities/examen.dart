import 'package:equatable/equatable.dart';

import '../../../expediente/domain/entities/expediente.dart';

class ResultadoAnalito extends Equatable {
  const ResultadoAnalito({required this.analito, required this.valor, this.unidad, this.rangoReferencia, this.confianzaOcr, this.validadoPorMedico = false});
  final String analito;
  final String valor;
  final String? unidad;
  final String? rangoReferencia;
  final double? confianzaOcr;
  final bool validadoPorMedico;

  Map<String, dynamic> aJson() => {
        'analito': analito,
        'valor': valor,
        if (unidad != null && unidad!.isNotEmpty) 'unidad': unidad,
        if (rangoReferencia != null && rangoReferencia!.isNotEmpty) 'rangoReferencia': rangoReferencia,
      };

  @override
  List<Object?> get props => [analito, valor, unidad, rangoReferencia];
}

/// Categoría para lo que no está en el catálogo.
const categoriaOtro = 'Otro';

/// Categoría y tipo de un examen. Con origen IA es una sugerencia que el paciente puede corregir.
class ClasificacionExamen extends Equatable {
  const ClasificacionExamen({required this.categoria, required this.tipo, required this.origen, this.confianza});
  final String categoria;
  final String tipo;

  /// IA (sugerido por la app) o PACIENTE (elegido o corregido por el paciente).
  final String origen;

  /// 0–1, solo en las sugerencias de la IA.
  final double? confianza;

  bool get sugeridaPorIa => origen == 'IA';

  /// "92 %" para mostrar junto a la sugerencia.
  String? get confianzaLegible => confianza == null ? null : '${(confianza! * 100).round()} %';

  @override
  List<Object?> get props => [categoria, tipo, origen, confianza];
}

class Examen extends Equatable {
  const Examen({
    required this.id,
    required this.pacienteId,
    required this.titulo,
    required this.tipoMime,
    required this.nombreArchivo,
    required this.estadoExtraccion,
    required this.resultados,
    required this.validadoPorMedico,
    required this.cargadoEn,
    this.solicitudId,
    this.fechaExamen,
    this.clasificacion,
    this.tituloAutomatico = false,
  });
  final String id;
  final String pacienteId;
  final String titulo;
  final String tipoMime;
  final String nombreArchivo;
  final String estadoExtraccion;
  final List<ResultadoAnalito> resultados;
  final bool validadoPorMedico;
  final DateTime cargadoEn;
  final String? solicitudId;
  final DateTime? fechaExamen;
  final ClasificacionExamen? clasificacion;

  /// El paciente no le puso nombre: el título es el tipo sugerido o elegido.
  final bool tituloAutomatico;

  /// Sin categoría ni tipo: la IA no reconoció el documento y el paciente debe elegirlos.
  bool get sinClasificar => clasificacion == null;

  bool get esPdf => tipoMime == 'application/pdf';
  String get estadoLegible => switch (estadoExtraccion) {
        'EXTRAIDO' => 'Valores por revisar',
        'CONFIRMADO' => validadoPorMedico ? 'Validado por médico' : 'Valores confirmados',
        _ => 'Guardado como adjunto',
      };

  @override
  List<Object?> get props => [id, estadoExtraccion, resultados, validadoPorMedico, clasificacion, titulo];
}

class SolicitudExamen extends Equatable {
  const SolicitudExamen({
    required this.id,
    required this.pacienteId,
    required this.examenes,
    required this.indicaciones,
    required this.estado,
    required this.creadaEn,
    this.medico,
    this.citaId,
    this.examenResultadoIds = const [],
    this.completadaEn,
    this.motivoAnulacion,
    this.anuladaEn,
  });
  final String id;
  final String pacienteId;
  final List<String> examenes;
  final String indicaciones;
  final String estado;
  final DateTime creadaEn;
  final MedicoResumen? medico;
  final String? citaId;
  final List<String> examenResultadoIds;
  final DateTime? completadaEn;
  final String? motivoAnulacion;
  final DateTime? anuladaEn;

  bool get pendiente => estado == 'PENDIENTE';
  bool get completada => estado == 'COMPLETADA';
  bool get anulada => estado == 'ANULADA';

  String get estadoLegible => switch (estado) {
        'PENDIENTE' => 'Pendiente',
        'COMPLETADA' => 'Resultados cargados',
        'ANULADA' => 'Anulada',
        _ => estado,
      };

  @override
  List<Object?> get props => [id, estado];
}

class CategoriaCatalogo {
  const CategoriaCatalogo(this.categoria, this.examenes);
  final String categoria;
  final List<String> examenes;
}

class ArchivoExamen {
  const ArchivoExamen({required this.bytes, required this.nombre});
  final List<int> bytes;
  final String nombre;
}
