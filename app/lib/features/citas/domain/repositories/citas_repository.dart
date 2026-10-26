import '../entities/cita.dart';

abstract class CitasRepository {
  Future<List<Franja>> disponibilidad(String medicoId, {DateTime? desde, int dias = 14});
  Future<Cita> agendar(SolicitudCita solicitud);
  Future<List<Cita>> listar({String? pacienteId, List<String>? estados});
  Future<Cita> obtener(String id);
  Future<(Cita, double)> cancelar(String id, String motivo);
  Future<Cita> marcarAtendida(String id, {String? notaClinica, List<String> diagnosticos = const []});
  Future<Cita> marcarNoAsistio(String id);
  Future<Cita> reportarProblema(String id, String motivo);
  Future<Cita> proponer(PropuestaSeguimiento propuesta);
  Future<Cita> responderPropuesta(String id, {required bool aceptar});
}
