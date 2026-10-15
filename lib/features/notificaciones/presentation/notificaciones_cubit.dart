import 'dart:async';

import '../../../core/estado/recurso.dart';
import '../domain/notificaciones.dart';

/// Bandeja global de notificaciones (se refresca cada minuto mientras hay sesión).
class NotificacionesCubit extends RecursoCubit<BandejaNotificaciones> {
  NotificacionesCubit(this.consultar);
  final ConsultarNotificaciones consultar;
  Timer? _temporizador;

  int get noLeidas => state.datosOpcional?.noLeidas ?? 0;

  void iniciar() {
    cargar();
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 60), (_) => cargar());
  }

  void detener() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> cargar() => ejecutar(consultar.call, silencioso: true);

  Future<void> marcarLeida(String id) async {
    await consultar.marcarLeida(id);
    await cargar();
  }

  Future<void> marcarTodas() async {
    await consultar.marcarTodas();
    await cargar();
  }

  @override
  Future<void> close() {
    detener();
    return super.close();
  }
}
