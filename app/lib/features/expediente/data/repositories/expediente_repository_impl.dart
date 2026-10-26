import '../../../../core/utils/json.dart';
import '../../domain/entities/expediente.dart';
import '../../domain/repositories/expediente_repository.dart';
import '../datasources/expediente_remote_data_source.dart';

class ExpedienteRepositoryImpl implements ExpedienteRepository {
  const ExpedienteRepositoryImpl(this._r);
  final ExpedienteRemoteDataSource _r;

  @override
  Future<ResumenExpediente> resumen(String pacienteId) async => ExpedienteMapper.resumen(await _r.resumen(pacienteId));

  @override
  Future<PaginaEventos> lineaDeTiempo(String pacienteId, {String? tipo, int pagina = 1}) async {
    final j = await _r.lineaDeTiempo(pacienteId, tipo, pagina);
    return PaginaEventos(
      items: listaDeMapas(j['items']).map(ExpedienteMapper.evento).toList(),
      total: (j['total'] as num).toInt(),
      categoriasPermitidas: textos(j['categoriasPermitidas']),
      esTitular: j['esTitular'] as bool? ?? false,
    );
  }

  @override
  Future<EventoClinico> agregarEvento(String pacienteId, NuevoEvento evento) async =>
      ExpedienteMapper.evento(await _r.agregarEvento(pacienteId, evento));

  @override
  Future<void> actualizarAntecedentes(String pacienteId, List<String> antecedentes) => _r.antecedentes(pacienteId, antecedentes);

  @override
  Future<String> exportarPdf(String pacienteId) => _r.exportar(pacienteId);

  @override
  Future<List<Permiso>> permisos(String pacienteId) async => (await _r.permisos(pacienteId)).map(ExpedienteMapper.permiso).toList();

  @override
  Future<void> concederAcceso(String pacienteId, NuevoPermiso permiso) => _r.conceder(pacienteId, permiso);

  @override
  Future<void> revocarAcceso(String permisoId) => _r.revocar(permisoId);

  @override
  Future<List<RegistroAcceso>> auditoria(String pacienteId) async => (await _r.auditoria(pacienteId)).map(ExpedienteMapper.acceso).toList();

  @override
  Future<List<PacienteAutorizado>> misPacientes() async => (await _r.misPacientes()).map(ExpedienteMapper.pacienteAutorizado).toList();

  @override
  Future<List<Referencia>> referencias() async => (await _r.referencias()).map(ExpedienteMapper.referencia).toList();

  @override
  Future<void> referir(String pacienteId, String medicoDestinoId, String motivo) => _r.referir(pacienteId, medicoDestinoId, motivo);

  @override
  Future<void> responderReferencia(String referenciaId, {required bool aprobar}) => _r.responder(referenciaId, aprobar);
}
