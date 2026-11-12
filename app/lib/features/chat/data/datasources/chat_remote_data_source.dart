import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/mensaje_chat.dart';

/// Endpoints del chat: /chat/citas/:citaId/mensajes, /leidos y /chat/no-leidos.
class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> conversacion(String citaId, DateTime? despuesDe) async =>
      mapa(await _api.get('/chat/citas/$citaId/mensajes', query: {if (despuesDe != null) 'despuesDe': Formatos.iso(despuesDe)}));

  Future<Map<String, dynamic>> enviar(String citaId, String texto) async =>
      mapa(await _api.post('/chat/citas/$citaId/mensajes', data: {'texto': texto}));

  Future<void> marcarLeidos(String citaId) async {
    await _api.post('/chat/citas/$citaId/leidos');
  }

  Future<Map<String, dynamic>> noLeidos() async => mapa(await _api.get('/chat/no-leidos'));
}

class ChatMapper {
  static MensajeChat mensaje(Map<String, dynamic> j) => MensajeChat(
        id: j['id'] as String,
        autor: j['autor'] as String,
        texto: j['texto'] as String,
        enviadoEn: fecha(j['enviadoEn']),
        leidoEn: fechaOpcional(j['leidoEn']),
      );

  static ConversacionChat conversacion(Map<String, dynamic> j) => ConversacionChat(
        citaId: j['citaId'] as String,
        miParte: j['miParte'] as String,
        habilitado: j['habilitado'] as bool? ?? false,
        mensajes: listaDeMapas(j['mensajes']).map(mensaje).toList(),
      );

  static Map<String, int> noLeidos(Map<String, dynamic> j) => {
        for (final c in listaDeMapas(j['porCita'])) c['citaId'] as String: (c['noLeidos'] as num).toInt(),
      };
}
