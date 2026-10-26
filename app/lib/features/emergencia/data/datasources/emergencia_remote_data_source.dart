import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/ficha_emergencia.dart';

class EmergenciaRemoteDataSource {
  const EmergenciaRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> obtener(String id) async => mapa(await _api.get('/emergencia/fichas/$id'));
  Future<Map<String, dynamic>> guardar(String id, FichaEmergencia f) async => mapa(await _api.put('/emergencia/fichas/$id', data: {
        if (f.grupoSanguineo != null) 'grupoSanguineo': f.grupoSanguineo,
        'alergias': f.alergias,
        'condicionesCronicas': f.condicionesCronicas,
        'medicacionActual': f.medicacionActual,
        'contactos': f.contactos.map((c) => c.aJson()).toList(),
        'camposPublicos': f.camposPublicos,
      }));
  Future<Map<String, dynamic>> regenerar(String id) async => mapa(await _api.post('/emergencia/fichas/$id/qr'));
  Future<Map<String, dynamic>> escanear(String token) async => mapa(await _api.get('/emergencia/qr/${Uri.encodeComponent(token)}'));
}

class FichaMapper {
  static FichaEmergencia ficha(Map<String, dynamic> j) => FichaEmergencia(
        grupoSanguineo: textoOpcional(j['grupoSanguineo']),
        alergias: textos(j['alergias']),
        condicionesCronicas: textos(j['condicionesCronicas']),
        medicacionActual: textos(j['medicacionActual']),
        contactos: listaDeMapas(j['contactos'])
            .map((c) => ContactoEmergencia(nombre: c['nombre'] as String, parentesco: c['parentesco'] as String? ?? '', telefono: c['telefono'] as String))
            .toList(),
        camposPublicos: j['camposPublicos'] == null ? const [] : textos(j['camposPublicos']),
        tieneQr: j['tieneQr'] as bool? ?? false,
        qrGeneradoEn: fechaOpcional(j['qrGeneradoEn']),
      );

  static FichaEscaneada escaneada(Map<String, dynamic> j) {
    final p = mapa(j['paciente']);
    final f = mapa(j['ficha']);
    return FichaEscaneada(
      nombre: p['nombreCompleto'] as String,
      edad: (p['edad'] as num?)?.toInt() ?? 0,
      sexo: p['sexo'] as String? ?? '',
      nivel: f['nivel'] as String? ?? 'PUBLICO',
      ficha: ficha(f),
    );
  }
}
