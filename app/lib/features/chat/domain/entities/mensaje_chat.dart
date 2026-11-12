import 'package:equatable/equatable.dart';

/// Mensaje del chat privado entre el paciente y el médico de una cita.
class MensajeChat extends Equatable {
  const MensajeChat({required this.id, required this.autor, required this.texto, required this.enviadoEn, this.leidoEn});
  final String id;

  /// PACIENTE o MEDICO.
  final String autor;
  final String texto;
  final DateTime enviadoEn;
  final DateTime? leidoEn;

  bool get leido => leidoEn != null;

  @override
  List<Object?> get props => [id, leidoEn];
}

/// Conversación de una cita vista por quien la abre.
class ConversacionChat extends Equatable {
  const ConversacionChat({required this.citaId, required this.miParte, required this.habilitado, required this.mensajes});
  final String citaId;

  /// Parte del usuario en la cita: PACIENTE o MEDICO.
  final String miParte;

  /// Solo se escribe con la cita confirmada o atendida.
  final bool habilitado;

  /// En orden de envío, del más antiguo al más reciente.
  final List<MensajeChat> mensajes;

  bool esMio(MensajeChat m) => m.autor == miParte;

  /// Agrega los mensajes nuevos sin repetir los que ya estaban.
  ConversacionChat conNuevos(List<MensajeChat> nuevos, {bool? habilitado}) {
    final ids = mensajes.map((m) => m.id).toSet();
    final combinados = [...mensajes, ...nuevos.where((m) => !ids.contains(m.id))]..sort((a, b) => a.enviadoEn.compareTo(b.enviadoEn));
    return ConversacionChat(citaId: citaId, miParte: miParte, habilitado: habilitado ?? this.habilitado, mensajes: combinados);
  }

  @override
  List<Object?> get props => [citaId, habilitado, mensajes];
}
