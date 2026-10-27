import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/recordatorio.dart';

class RecordatoriosRemoteDataSource {
  const RecordatoriosRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> preferencias() async => mapa(await _api.get('/recordatorios/preferencias'));

  Future<Map<String, dynamic>> actualizar(PreferenciasRecordatorio p) async => mapa(await _api.put('/recordatorios/preferencias', data: {
        'citas': p.citas,
        'medicamentos': p.medicamentos,
        'examenes': p.examenes,
      }));

  Future<List<Map<String, dynamic>>> proximos(String? pacienteId) async =>
      listaDeMapas(await _api.get('/recordatorios/proximos', query: {if (pacienteId != null) 'pacienteId': pacienteId}));
}

class RecordatorioMapper {
  static PreferenciasRecordatorio preferencias(Map<String, dynamic> j) => PreferenciasRecordatorio(
        citas: j['citas'] as bool? ?? true,
        medicamentos: j['medicamentos'] as bool? ?? true,
        examenes: j['examenes'] as bool? ?? true,
      );

  static Recordatorio recordatorio(Map<String, dynamic> j) => Recordatorio(
        tipo: TipoRecordatorio.desdeCodigo(j['tipo'] as String),
        pacienteId: j['pacienteId'] as String,
        pacienteNombre: j['pacienteNombre'] as String? ?? '',
        programadoPara: fecha(j['programadoPara']),
        titulo: j['titulo'] as String,
        mensaje: j['mensaje'] as String,
      );
}
