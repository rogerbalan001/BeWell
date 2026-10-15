import 'package:equatable/equatable.dart';

class Notificacion extends Equatable {
  const Notificacion({required this.id, required this.tipo, required this.titulo, required this.mensaje, required this.leida, required this.creadaEn, this.datos = const {}});
  final String id, tipo, titulo, mensaje;
  final bool leida;
  final DateTime creadaEn;
  final Map<String, String> datos;
  @override
  List<Object?> get props => [id, leida];
}

class BandejaNotificaciones {
  const BandejaNotificaciones(this.items, this.noLeidas);
  final List<Notificacion> items;
  final int noLeidas;
}

abstract class NotificacionesRepository {
  Future<BandejaNotificaciones> bandeja();
  Future<void> marcarLeida(String id);
  Future<void> marcarTodas();
}

class ConsultarNotificaciones {
  const ConsultarNotificaciones(this._r);
  final NotificacionesRepository _r;
  Future<BandejaNotificaciones> call() => _r.bandeja();
  Future<void> marcarLeida(String id) => _r.marcarLeida(id);
  Future<void> marcarTodas() => _r.marcarTodas();
}
