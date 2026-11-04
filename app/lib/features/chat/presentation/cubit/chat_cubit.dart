import 'dart:async';

import '../../../../core/estado/recurso.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/usecases/chat_usecases.dart';

/// Cada cuánto se piden los mensajes nuevos (criterio: aparecen en máximo 5 s, sin recargar).
const intervaloChat = Duration(seconds: 5);

/// Conversación abierta: carga los mensajes, pide los nuevos cada 5 s y marca como leídos los recibidos.
class ChatCubit extends RecursoCubit<ConversacionChat> {
  ChatCubit(this._chat, {Duration? intervalo = intervaloChat}) : _intervalo = intervalo;
  final ConversarEnCita _chat;
  final Duration? _intervalo;
  Timer? _temporizador;
  String? _citaId;
  bool _actualizando = false;

  Future<void> abrir(String citaId) async {
    _citaId = citaId;
    await ejecutar(() => _chat.abrir(citaId));
    await _marcarLeidosSiHay(state.datosOpcional?.mensajes ?? const []);
    final intervalo = _intervalo;
    if (intervalo != null) {
      _temporizador?.cancel();
      _temporizador = Timer.periodic(intervalo, (_) => actualizar());
    }
  }

  /// Pide solo los mensajes posteriores al último que ya se ve.
  Future<void> actualizar() async {
    final actual = state.datosOpcional;
    final citaId = _citaId;
    if (actual == null || citaId == null || _actualizando || isClosed) return;
    _actualizando = true;
    try {
      final ultimo = actual.mensajes.isEmpty ? null : actual.mensajes.last.enviadoEn;
      final r = await _chat.nuevos(citaId, ultimo);
      if (isClosed) return;
      final datos = state.datosOpcional ?? actual;
      if (r.mensajes.isNotEmpty || r.habilitado != datos.habilitado) {
        emit(RecursoListo(datos.conNuevos(r.mensajes, habilitado: r.habilitado), version: DateTime.now().microsecondsSinceEpoch));
        await _marcarLeidosSiHay(r.mensajes);
      }
    } catch (_) {
      // Un fallo de red al actualizar no borra la conversación: se reintenta en el siguiente ciclo.
    } finally {
      _actualizando = false;
    }
  }

  /// Envía un mensaje y lo agrega a la conversación. Devuelve el error o null.
  Future<String?> enviar(String texto) async {
    final citaId = _citaId;
    final limpio = texto.trim();
    if (citaId == null || limpio.isEmpty) return 'Escribe un mensaje';
    if (limpio.length > longitudMaximaMensaje) return 'El mensaje no puede superar $longitudMaximaMensaje caracteres';
    MensajeChat? enviado;
    final error = await intentar(() async => enviado = await _chat.enviar(citaId, limpio));
    final actual = state.datosOpcional;
    if (error == null && enviado != null && actual != null && !isClosed) {
      emit(RecursoListo(actual.conNuevos([enviado!]), version: DateTime.now().microsecondsSinceEpoch));
    }
    return error;
  }

  Future<void> _marcarLeidosSiHay(List<MensajeChat> mensajes) async {
    final c = state.datosOpcional;
    final citaId = _citaId;
    if (c == null || citaId == null) return;
    if (mensajes.any((m) => !c.esMio(m) && !m.leido)) {
      await intentar(() => _chat.marcarLeidos(citaId));
    }
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
