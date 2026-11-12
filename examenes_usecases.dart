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
/// El nombre es opcional: si no se escribe, la app sugiere la categoría y el tipo.
class SubirExamen {
  const SubirExamen(this._r);
  final ExamenesRepository _r;
  static const tamanoMaximo = 10 * 1024 * 1024;
  static const extensiones = ['pdf', 'jpg', 'jpeg', 'png'];

  Future<Examen> call({required String pacienteId, String? titulo, required ArchivoExamen archivo, String? solicitudId, DateTime? fechaExamen}) =>
      _r.subir(pacienteId: pacienteId, titulo: titulo, archivo: archivo, solicitudId: solicitudId, fechaExamen: fechaExamen);
}

/// HU: el paciente corrige la categoría y el tipo sugeridos, o los elige si la app no los reconoció.
class ClasificarExamen {
  const ClasificarExamen(this._r);
  final ExamenesRepository _r;

  /// Categorías del catálogo (con sus exámenes) más "Otro".
  Future<List<CategoriaCatalogo>> categorias() async => [...await _r.catalogo(), const CategoriaCatalogo(categoriaOtro, [])];

  Future<Examen> call(String examenId, {required String categoria, required String tipo}) =>
      _r.corregirClasificacion(examenId, categoria: categoria, tipo: tipo.trim());
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

/// HU médico: seguir el estado de las órdenes del paciente y anular las que sobran.
class GestionarOrdenesExamen {
  const GestionarOrdenesExamen(this._r);
  final ExamenesRepository _r;
  static const motivoMinimo = 5;

  Future<List<SolicitudExamen>> listar(String pacienteId) => _r.solicitudes(pacienteId: pacienteId);
  Future<SolicitudExamen> anular(String solicitudId, String motivo) => _r.anularSolicitud(solicitudId, motivo.trim());
}
