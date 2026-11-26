import '../network/api_client.dart';
import '../utils/json.dart';
import 'push_navegador.dart';

/// HU: recibir los recordatorios como notificaciones en el teléfono, aunque no se abra la app.
class NotificacionesPush {
  const NotificacionesPush(this._api);
  final ApiClient _api;

  bool get disponible => pushDisponible;
  String get permiso => permisoPush;
  bool get activas => permisoPush == 'granted';

  /// Pide permiso en el teléfono y registra la suscripción en el servidor. Devuelve false si no hubo permiso.
  Future<bool> activar() async {
    final clave = mapa(await _api.get('/notificaciones/push/clave'))['clavePublica'] as String;
    final suscripcion = await suscribirPush(clave);
    if (suscripcion == null) return false;
    await _api.post('/notificaciones/push/suscripcion', data: suscripcion.aJson());
    return true;
  }

  /// Manda un aviso de prueba a los teléfonos suscritos; devuelve cuántos lo aceptaron.
  Future<int> probar() async => (mapa(await _api.post('/notificaciones/push/prueba'))['enviadas'] as num?)?.toInt() ?? 0;
}
