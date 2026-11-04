import '../../domain/entities/mensaje_chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._r);
  final ChatRemoteDataSource _r;

  @override
  Future<ConversacionChat> conversacion(String citaId, {DateTime? despuesDe}) async => ChatMapper.conversacion(await _r.conversacion(citaId, despuesDe));

  @override
  Future<MensajeChat> enviar(String citaId, String texto) async => ChatMapper.mensaje(await _r.enviar(citaId, texto));

  @override
  Future<void> marcarLeidos(String citaId) => _r.marcarLeidos(citaId);

  @override
  Future<Map<String, int>> noLeidos() async => ChatMapper.noLeidos(await _r.noLeidos());
}
