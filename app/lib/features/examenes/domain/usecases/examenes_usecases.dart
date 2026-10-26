import '../entities/examen.dart';
import '../repositories/examenes_repository.dart';

class ListarExamenes {
  const ListarExamenes(this._r);
  final ExamenesRepository _r;
  Future<List<Examen>> call(String pacienteId) => _r.listar(pacienteId);
  Future<List<SolicitudExamen>> solicitudes({String? pacienteId}) => _r.solicitudes(pacienteId: pacienteId);
  Future<String> urlArchivo(String examenId) => _r.urlArchivo(examenId);
}

/// HU: subir fotos o PDF de mis exámenes (JPG, PNG o PDF de hasta 10 MB) y extraer valores.
class SubirExamen {
  const SubirExamen(this._r);
  final ExamenesRepository _r;
  static const tamanoMaximo = 10 * 1024 * 1024;
  static const extensiones = ['pdf', 'jpg', 'jpeg', 'png'];

  Future<Examen> call({required String pacienteId, required String titulo, required ArchivoExamen archivo, String? solicitudId, DateTime? fechaExamen}) =>
      _r.subir(pacienteId: pacienteId, titulo: titulo, archivo: archivo, solicitudId: solicitudId, fechaExamen: fechaExamen);
}

/// El paciente corrige los valores extraídos antes de guardar.
class ConfirmarResultados {
  const ConfirmarResultados(this._r);
  final ExamenesRepository _r;
  Future<Examen> call(String examenId, List<ResultadoAnalito> resultados) => _r.confirmarResultados(examenId, resultados);
  Future<Examen> validarComoMedico(String examenId) => _r.validar(examenId);
}

/// HU médico: solicitar exámenes desde la app.
class SolicitarExamenes {
  const SolicitarExamenes(this._r);
  final ExamenesRepository _r;
  Future<List<CategoriaCatalogo>> catalogo() => _r.catalogo();
  Future<SolicitudExamen> call({required String pacienteId, required List<String> examenes, String? indicaciones, String? citaId}) =>
      _r.solicitar(pacienteId: pacienteId, examenes: examenes, indicaciones: indicaciones, citaId: citaId);
}
