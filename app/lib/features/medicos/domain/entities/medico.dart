import 'package:equatable/equatable.dart';

class PoliticaCancelacion extends Equatable {
  const PoliticaCancelacion({required this.tipo, required this.horasMinimasAviso, required this.porcentajePenalizacion, required this.descripcion});
  final String tipo;
  final int horasMinimasAviso;
  final double porcentajePenalizacion;
  final String descripcion;

  String get nombre => switch (tipo) { 'FLEXIBLE' => 'Flexible', 'ESTRICTA' => 'Estricta', _ => 'Moderada' };

  @override
  List<Object?> get props => [tipo, horasMinimasAviso, porcentajePenalizacion];
}

class BloqueHorario extends Equatable {
  const BloqueHorario({required this.diaSemana, required this.horaInicio, required this.horaFin, required this.duracionCitaMin});
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final int duracionCitaMin;

  Map<String, dynamic> aJson() => {'diaSemana': diaSemana, 'horaInicio': horaInicio, 'horaFin': horaFin, 'duracionCitaMin': duracionCitaMin};

  @override
  List<Object?> get props => [diaSemana, horaInicio, horaFin, duracionCitaMin];
}

class Credencial extends Equatable {
  const Credencial({required this.id, required this.tipo, required this.numero, required this.estado, this.observaciones, this.enviadaEn});
  final String id;
  final String tipo;
  final String numero;
  final String estado;
  final String? observaciones;
  final DateTime? enviadaEn;

  String get nombreTipo => switch (tipo) { 'TITULO' => 'Título de médico', 'COLEGIATURA' => 'Colegiatura', _ => 'Cédula de identidad' };

  @override
  List<Object?> get props => [id, estado];
}

/// Médico del directorio. Los campos de verificación y horario solo vienen
/// en la vista completa (el propio médico o el administrador).
class Medico extends Equatable {
  const Medico({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.especialidades,
    required this.tarifa,
    required this.moneda,
    required this.verificado,
    required this.calificacion,
    required this.totalResenas,
    required this.modalidades,
    required this.politica,
    required this.tieneHorario,
    this.direccion,
    this.biografia,
    this.estadoVerificacion,
    this.credenciales = const [],
    this.horario = const [],
  });

  final String id;
  final String nombres;
  final String apellidos;
  final List<String> especialidades;
  final double tarifa;
  final String moneda;
  final bool verificado;
  final double calificacion;
  final int totalResenas;
  final List<String> modalidades;
  final PoliticaCancelacion politica;
  final bool tieneHorario;
  final String? direccion;
  final String? biografia;
  final String? estadoVerificacion;
  final List<Credencial> credenciales;
  final List<BloqueHorario> horario;

  String get nombreCompleto => '$nombres $apellidos';
  String get especialidad => especialidades.isEmpty ? 'Medicina' : especialidades.first;
  bool get ofreceVirtual => modalidades.contains('VIRTUAL');
  bool get ofrecePresencial => modalidades.contains('PRESENCIAL');

  @override
  List<Object?> get props => [id, calificacion, totalResenas, estadoVerificacion, credenciales, horario, politica, modalidades];
}
