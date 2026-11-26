import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'push_navegador.dart';

JSObject? get _navegador => globalContext['navigator'] as JSObject?;
JSObject? get _sw => _navegador?['serviceWorker'] as JSObject?;
JSObject? get _notification => globalContext['Notification'] as JSObject?;

/// El navegador soporta service workers, Push API y notificaciones.
bool get pushDisponible => _sw != null && _notification != null && globalContext.has('PushManager');

/// 'granted', 'denied', 'default' o 'no-soportado'.
String get permisoPush => pushDisponible ? ((_notification!['permission'] as JSString?)?.toDart ?? 'default') : 'no-soportado';

/// Pide permiso, registra el service worker de notificaciones y suscribe este navegador.
/// Devuelve null si la persona no dio permiso.
Future<SuscripcionNavegador?> suscribirPush(String clavePublica) async {
  if (!pushDisponible) return null;
  final permiso = await _notification!.callMethod<JSPromise<JSString>>('requestPermission'.toJS).toDart;
  if (permiso.toDart != 'granted') return null;

  final opciones = JSObject()..['scope'] = './bewell-push/'.toJS;
  final registro = await _sw!.callMethod<JSPromise<JSObject>>('register'.toJS, 'push-sw.js'.toJS, opciones).toDart;

  // El service worker tiene que estar activo antes de suscribirse.
  for (var i = 0; i < 50 && registro['active'] == null; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  final gestor = registro['pushManager'] as JSObject;
  var suscripcion = await gestor.callMethod<JSPromise<JSObject?>>('getSubscription'.toJS).toDart;
  if (suscripcion == null) {
    final clave = base64Url.decode(base64Url.normalize(clavePublica));
    final pedido = JSObject()
      ..['userVisibleOnly'] = true.toJS
      ..['applicationServerKey'] = clave.toJS;
    suscripcion = await gestor.callMethod<JSPromise<JSObject>>('subscribe'.toJS, pedido).toDart;
  }
  final datos = suscripcion.callMethod<JSObject>('toJSON'.toJS);
  final claves = datos['keys'] as JSObject;
  return SuscripcionNavegador(
    endpoint: (datos['endpoint'] as JSString).toDart,
    p256dh: (claves['p256dh'] as JSString).toDart,
    auth: (claves['auth'] as JSString).toDart,
  );
}
