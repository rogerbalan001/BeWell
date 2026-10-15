import '../../domain/entities/medico.dart';
import '../../domain/repositories/medicos_repository.dart';
import '../datasources/medicos_remote_data_source.dart';

class MedicosRepositoryImpl implements MedicosRepository {
  const MedicosRepositoryImpl(this._r);
  final MedicosRemoteDataSource _r;

  @override
  Future<List<Medico>> directorio({String? especialidad, String? texto, String? modalidad}) async => (await _r.directorio({
        if (especialidad != null) 'especialidad': especialidad,
        if (texto != null && texto.isNotEmpty) 'q': texto,
        if (modalidad != null) 'modalidad': modalidad,
      }))
          .map(MedicoMapper.desdeJson)
          .toList();

  @override
  Future<List<String>> especialidades() => _r.especialidades();

  @override
  Future<Medico> obtener(String id) async => MedicoMapper.desdeJson(await _r.obtener(id));

  @override
  Future<List<PoliticaCancelacion>> catalogoPoliticas() async => (await _r.politicas()).map(MedicoMapper.politica).toList();

  @override
  Future<Medico> miPerfil() async => MedicoMapper.desdeJson(await _r.yo());

  @override
  Future<Medico> actualizarPerfil({String? biografia, String? direccion, double? tarifa}) async => MedicoMapper.desdeJson(await _r.actualizar({
        if (biografia != null) 'biografia': biografia,
        if (direccion != null) 'direccionConsultorio': direccion,
        if (tarifa != null) 'tarifaConsulta': tarifa,
      }));

  @override
  Future<void> configurarHorario(List<BloqueHorario> bloques, List<String> modalidades) =>
      _r.horario({'bloques': bloques.map((b) => b.aJson()).toList(), 'modalidades': modalidades});

  @override
  Future<void> configurarPolitica(String tipo) => _r.politica(tipo);

  @override
  Future<void> subirCredencial(String tipo, String numero, List<int> bytes, String nombreArchivo) =>
      _r.subirCredencial(tipo, numero, bytes, nombreArchivo);

  @override
  Future<List<Medico>> pendientesDeVerificacion() async => (await _r.pendientes()).map(MedicoMapper.desdeJson).toList();

  @override
  Future<void> aprobarCredencial(String medicoId, String credencialId) => _r.aprobar(medicoId, credencialId);

  @override
  Future<void> rechazarCredencial(String medicoId, String credencialId, String motivo) => _r.rechazar(medicoId, credencialId, motivo);

  @override
  Future<String> urlCredencial(String medicoId, String credencialId) => _r.url(medicoId, credencialId);
}
