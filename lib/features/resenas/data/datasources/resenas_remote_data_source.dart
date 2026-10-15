import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/resena.dart';

class ResenasRemoteDataSource {
  const ResenasRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> deMedico(String id) async => mapa(await _api.get('/resenas/medico/$id'));

  Future<Map<String, dynamic>?> deCita(String citaId) async {
    try {
      return mapa(await _api.get('/resenas/cita/$citaId'));
    } on Failure catch (f) {
      if (f.noEncontrado) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> publicar(String citaId, Calificaciones c) async =>
      mapa(await _api.post('/resenas', data: {'citaId': citaId, ..._cuerpo(c)}));

  Future<Map<String, dynamic>> editar(String id, Calificaciones c) async => mapa(await _api.patch('/resenas/$id', data: _cuerpo(c)));

  Map<String, dynamic> _cuerpo(Calificaciones c) => {
        'puntualidad': c.puntualidad,
        'trato': c.trato,
        'claridad': c.claridad,
        'instalaciones': c.instalaciones,
        if (c.comentario != null && c.comentario!.isNotEmpty) 'comentario': c.comentario,
      };
}

class ResenaMapper {
  static Resena desdeJson(Map<String, dynamic> j) => Resena(
        id: j['id'] as String,
        citaId: j['citaId'] as String,
        puntualidad: (j['puntualidad'] as num).toInt(),
        trato: (j['trato'] as num).toInt(),
        claridad: (j['claridad'] as num).toInt(),
        instalaciones: (j['instalaciones'] as num).toInt(),
        promedio: numero(j['promedio']),
        publicadaEn: fecha(j['publicadaEn']),
        editable: j['editable'] as bool? ?? false,
        comentario: textoOpcional(j['comentario']),
        autor: textoOpcional(j['autor']),
      );

  static EstadisticasResenas estadisticas(Map<String, dynamic> j) => EstadisticasResenas(
        total: (j['total'] as num).toInt(),
        promedio: numero(j['promedio']),
        puntualidad: numero(j['puntualidad']),
        trato: numero(j['trato']),
        claridad: numero(j['claridad']),
        instalaciones: numero(j['instalaciones']),
      );
}
