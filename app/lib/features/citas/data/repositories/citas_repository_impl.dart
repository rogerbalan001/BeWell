import '../../../../core/utils/json.dart';
import '../../domain/entities/cita.dart';
import '../../domain/repositories/citas_repository.dart';
import '../datasources/citas_remote_data_source.dart';

class CitasRepositoryImpl implements CitasRepository {
  const CitasRepositoryImpl(this._r);
  final CitasRemoteDataSource _r;

  @override
  Future<List<Franja>> disponibilidad(String medicoId, {DateTime? desde, int dias = 14}) async =>
      (await _r.disponibilidad(medicoId, desde, dias)).map(CitaMapper.franja).toList();

  @override
  Future<Cita> agendar(SolicitudCita solicitud) async => CitaMapper.desdeJson(await _r.agendar(solicitud));

  @override
  Future<List<Cita>> listar({String? pacienteId, List<String>? estados}) async =>
      (await _r.listar(pacienteId, estados)).map(CitaMapper.desdeJson).toList();

  @override
  Future<Cita> obtener(String id) async => CitaMapper.desdeJson(await _r.obtener(id));

  @override
  Future<(Cita, double)> cancelar(String id, String motivo) async {
    final j = await _r.accion(id, 'cancelar', {'motivo': motivo});
    return (CitaMapper.desdeJson(j), numero(j['reembolso']));
  }

  @override
  Future<Cita> marcarAtendida(String id, {String? notaClinica, List<String> diagnosticos = const []}) async =>
      CitaMapper.desdeJson(await _r.accion(id, 'atender', {
        if (notaClinica != null && notaClinica.isNotEmpty) 'notaClinica': notaClinica,
        'diagnosticos': diagnosticos,
      }));

  @override
  Future<Cita> marcarNoAsistio(String id) async => CitaMapper.desdeJson(await _r.accion(id, 'no-asistio'));

  @override
  Future<Cita> reportarProblema(String id, String motivo) async =>
      CitaMapper.desdeJson(await _r.accion(id, 'reportar-problema', {'motivo': motivo}));

  @override
  Future<Cita> proponer(PropuestaSeguimiento propuesta) async => CitaMapper.desdeJson(await _r.proponer(propuesta));

  @override
  Future<Cita> responderPropuesta(String id, {required bool aceptar}) async =>
      CitaMapper.desdeJson(await _r.accion(id, aceptar ? 'aceptar' : 'rechazar'));
}
