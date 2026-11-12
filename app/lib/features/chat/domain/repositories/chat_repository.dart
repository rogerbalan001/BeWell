import '../entities/mensaje_chat.dart';

abstract class ChatRepository {
  /// Mensajes de la cita; con [despuesDe], solo los enviados después.
  Future<ConversacionChat> conversacion(String citaId, {DateTime? despuesDe});
  Future<MensajeChat> enviar(String citaId, String texto);
  Future<void> marcarLeidos(String citaId);

  /// Mensajes sin leer por cita.
  Future<Map<String, int>> noLeidos();
}
