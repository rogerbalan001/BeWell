import 'push_navegador.dart';

/// Este dispositivo no puede recibir notificaciones push del navegador.
bool get pushDisponible => false;

/// 'granted', 'denied', 'default' o 'no-soportado'.
String get permisoPush => 'no-soportado';

Future<SuscripcionNavegador?> suscribirPush(String clavePublica) async => null;
