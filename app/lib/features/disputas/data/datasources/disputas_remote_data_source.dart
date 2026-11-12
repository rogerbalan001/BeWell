import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/disputa.dart';

/// Endpoints del administrador: GET /pagos/disputas y POST /pagos/:id/resolver.
class DisputasRemoteDataSource {
  const DisputasRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listar() async => listaDeMapas(await _api.get('/pagos/disputas'));

  Future<Map<String, dynamic>> resolver(String pagoId, AccionDisputa accion, String? nota) async =>
      mapa(await _api.post('/pagos/$pagoId/resolver', data: {
        'accion': accion.codigo,
        if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
      }));
}

class DisputaMapper {
  static Disputa desdeJson(Map<String, dynamic> j) => Disputa(
        pagoId: j['id'] as String,
        citaId: j['citaId'] as String,
        monto: numero(j['monto']),
        moneda: j['moneda'] as String? ?? 'USD',
        estado: j['estado'] as String,
        motivo: j['motivoDisputa'] as String? ?? '',
        pacienteNombre: j['pacienteNombre'] as String? ?? 'Paciente',
        medicoNombre: j['medicoNombre'] as String? ?? 'Médico',
        abiertaEn: fechaOpcional(j['abiertaEn']),
      );
}
