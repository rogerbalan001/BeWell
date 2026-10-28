import '../../../../core/utils/json.dart';
import '../../domain/entities/examen.dart';
import '../../domain/repositories/examenes_repository.dart';
import '../datasources/examenes_remote_data_source.dart';

class ExamenesRepositoryImpl implements ExamenesRepository {
  const ExamenesRepositoryImpl(this._r);
  final ExamenesRemoteDataSource _r;

  @override
  Future<List<Examen>> listar(String pacienteId) async => (await _r.listar(pacienteId)).map(ExamenMapper.examen).toList();

  @override
  Future<List<SolicitudExamen>> solicitudes({String? pacienteId}) async => (await _r.solicitudes(pacienteId)).map(ExamenMapper.solicitud).toList();

  @override
  Future<List<CategoriaCatalogo>> catalogo() async =>
      (await _r.catalogo()).map((c) => CategoriaCatalogo(c['categoria'] as String, textos(c['examenes']))).toList();

  @override
  Future<Examen> subir({required String pacienteId, required String titulo, required ArchivoExamen archivo, String? solicitudId, DateTime? fechaExamen}) async =>
      ExamenMapper.examen(await _r.subir(pacienteId, titulo, archivo, solicitudId, fechaExamen));

  @override
  Future<Examen> confirmarResultados(String examenId, List<ResultadoAnalito> resultados) async => ExamenMapper.examen(await _r.confirmar(examenId, resultados));

  @override
  Future<Examen> validar(String examenId) async => ExamenMapper.examen(await _r.validar(examenId));

  @override
  Future<String> urlArchivo(String examenId) => _r.url(examenId);

  @override
  Future<SolicitudExamen> solicitar({required String pacienteId, required List<String> examenes, String? indicaciones, String? citaId}) async =>
      ExamenMapper.solicitud(await _r.solicitar({
        'pacienteId': pacienteId,
        'examenes': examenes,
        if (indicaciones != null && indicaciones.isNotEmpty) 'indicaciones': indicaciones,
        if (citaId != null) 'citaId': citaId,
      }));

  @override
  Future<SolicitudExamen> anularSolicitud(String solicitudId, String motivo) async => ExamenMapper.solicitud(await _r.anular(solicitudId, motivo));
}
