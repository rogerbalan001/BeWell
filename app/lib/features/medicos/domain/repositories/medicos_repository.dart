import '../entities/medico.dart';

abstract class MedicosRepository {
  Future<List<Medico>> directorio({String? especialidad, String? texto, String? modalidad});
  Future<List<String>> especialidades();
  Future<Medico> obtener(String id);
  Future<List<PoliticaCancelacion>> catalogoPoliticas();

  // Médico autenticado
  Future<Medico> miPerfil();
  Future<Medico> actualizarPerfil({String? biografia, String? direccion, double? tarifa});
  Future<void> configurarHorario(List<BloqueHorario> bloques, List<String> modalidades);
  Future<void> configurarPolitica(String tipo);
  Future<void> subirCredencial(String tipo, String numero, List<int> bytes, String nombreArchivo);

  // Administrador
  Future<List<Medico>> pendientesDeVerificacion();
  Future<void> aprobarCredencial(String medicoId, String credencialId);
  Future<void> rechazarCredencial(String medicoId, String credencialId, String motivo);
  Future<String> urlCredencial(String medicoId, String credencialId);
}
