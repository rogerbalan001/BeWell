import '../entities/expediente.dart';

abstract class ExpedienteRepository {
  Future<ResumenExpediente> resumen(String pacienteId);
  Future<PaginaEventos> lineaDeTiempo(String pacienteId, {String? tipo, int pagina = 1});
  Future<EventoClinico> agregarEvento(String pacienteId, NuevoEvento evento);
  Future<void> actualizarAntecedentes(String pacienteId, List<String> antecedentes);
  Future<String> exportarPdf(String pacienteId);

  Future<List<Permiso>> permisos(String pacienteId);
  Future<void> concederAcceso(String pacienteId, NuevoPermiso permiso);
  Future<void> revocarAcceso(String permisoId);
  Future<List<RegistroAcceso>> auditoria(String pacienteId);

  Future<List<PacienteAutorizado>> misPacientes();
  Future<List<Referencia>> referencias();
  Future<void> referir(String pacienteId, String medicoDestinoId, String motivo);
  Future<void> responderReferencia(String referenciaId, {required bool aprobar});
}
