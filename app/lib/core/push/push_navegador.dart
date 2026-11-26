/// Notificaciones push del navegador del teléfono (Web Push). En plataformas sin
/// navegador (pruebas, escritorio) se usa una versión vacía.
library;

export 'push_stub.dart' if (dart.library.js_interop) 'push_web.dart';

/// Datos que el navegador entrega al suscribirse y que el servidor necesita para enviar.
class SuscripcionNavegador {
  const SuscripcionNavegador({required this.endpoint, required this.p256dh, required this.auth});
  final String endpoint;
  final String p256dh;
  final String auth;

  Map<String, dynamic> aJson() => {'endpoint': endpoint, 'p256dh': p256dh, 'auth': auth};
}
