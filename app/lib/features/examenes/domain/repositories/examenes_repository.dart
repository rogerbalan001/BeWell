import '../entities/examen.dart';

abstract class ExamenesRepository {
  Future<List<Examen>> listar(String pacienteId);
  Future<List<SolicitudExamen>> solicitudes({String? pacienteId});
  Future<List<CategoriaCatalogo>> catalogo();
  Future<Examen> subir({required String pacienteId, required String titulo, required ArchivoExamen archivo, String? solicitudId, DateTime? fechaExamen});
  Future<Examen> confirmarResultados(String examenId, List<ResultadoAnalito> resultados);
  Future<Examen> validar(String examenId);
  Future<String> urlArchivo(String examenId);
  Future<SolicitudExamen> solicitar({required String pacienteId, required List<String> examenes, String? indicaciones, String? citaId});
  Future<SolicitudExamen> anularSolicitud(String solicitudId, String motivo);
}
