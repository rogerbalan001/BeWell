import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../domain/notificaciones.dart';

class NotificacionesRepositoryImpl implements NotificacionesRepository {
  const NotificacionesRepositoryImpl(this._api);
  final ApiClient _api;

  @override
  Future<BandejaNotificaciones> bandeja() async {
    final j = mapa(await _api.get('/notificaciones'));
    return BandejaNotificaciones(
      listaDeMapas(j['items'])
          .map((n) => Notificacion(
                id: n['id'] as String,
                tipo: n['tipo'] as String,
                titulo: n['titulo'] as String,
                mensaje: n['mensaje'] as String,
                leida: n['leida'] as bool? ?? false,
                creadaEn: fecha(n['creadaEn']),
                datos: (n['datos'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
              ))
          .toList(),
      (j['noLeidas'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> marcarLeida(String id) async => _api.post('/notificaciones/$id/leida');

  @override
  Future<void> marcarTodas() async => _api.post('/notificaciones/leer-todas');
}
