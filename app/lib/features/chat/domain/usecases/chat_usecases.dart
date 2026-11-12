import '../entities/mensaje_chat.dart';
import '../repositories/chat_repository.dart';

/// Máximo de caracteres por mensaje (igual que la API).
const longitudMaximaMensaje = 2000;

/// Chat privado con el médico (o el paciente) de una cita.
class ConversarEnCita {
  const ConversarEnCita(this._r);
  final ChatRepository _r;

  Future<ConversacionChat> abrir(String citaId) => _r.conversacion(citaId);
  Future<ConversacionChat> nuevos(String citaId, DateTime? despuesDe) => _r.conversacion(citaId, despuesDe: despuesDe);
  Future<MensajeChat> enviar(String citaId, String texto) => _r.enviar(citaId, texto.trim());
  Future<void> marcarLeidos(String citaId) => _r.marcarLeidos(citaId);

  /// Mensajes sin leer de una cita, para el contador del botón.
  Future<int> noLeidosDe(String citaId) async => (await _r.noLeidos())[citaId] ?? 0;
}
