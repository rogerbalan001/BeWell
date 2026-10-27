import 'package:equatable/equatable.dart';

/// Qué tipos de recordatorio quiere recibir el usuario (aplica a toda su familia).
class PreferenciasRecordatorio extends Equatable {
  const PreferenciasRecordatorio({required this.citas, required this.medicamentos, required this.examenes});
  final bool citas;
  final bool medicamentos;
  final bool examenes;

  PreferenciasRecordatorio copiarCon({bool? citas, bool? medicamentos, bool? examenes}) => PreferenciasRecordatorio(
        citas: citas ?? this.citas,
        medicamentos: medicamentos ?? this.medicamentos,
        examenes: examenes ?? this.examenes,
      );

  bool permite(TipoRecordatorio tipo) => switch (tipo) {
        TipoRecordatorio.citas => citas,
        TipoRecordatorio.medicamentos => medicamentos,
        TipoRecordatorio.examenes => examenes,
      };

  @override
  List<Object?> get props => [citas, medicamentos, examenes];
}

enum TipoRecordatorio {
  citas('CITAS', 'Citas', '24 horas y 1 hora antes de cada consulta'),
  medicamentos('MEDICAMENTOS', 'Medicamentos', 'En cada toma, según la dosis y horario del récipe'),
  examenes('EXAMENES', 'Exámenes', 'Si una orden sigue pendiente a 1, 3 y 7 días');

  const TipoRecordatorio(this.codigo, this.titulo, this.descripcion);
  final String codigo;
  final String titulo;
  final String descripcion;

  static TipoRecordatorio desdeCodigo(String codigo) => values.firstWhere((t) => t.codigo == codigo, orElse: () => TipoRecordatorio.citas);
}

/// Un recordatorio que llegará en los próximos días.
class Recordatorio extends Equatable {
  const Recordatorio({
    required this.tipo,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.programadoPara,
    required this.titulo,
    required this.mensaje,
  });
  final TipoRecordatorio tipo;
  final String pacienteId;
  final String pacienteNombre;
  final DateTime programadoPara;
  final String titulo;
  final String mensaje;

  @override
  List<Object?> get props => [tipo, pacienteId, programadoPara, titulo];
}
