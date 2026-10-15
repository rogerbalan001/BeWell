import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/medico.dart';

class MedicosRemoteDataSource {
  const MedicosRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> directorio(Map<String, dynamic> query) async => listaDeMapas(await _api.get('/medicos', query: query));
  Future<List<String>> especialidades() async => textos(await _api.get('/medicos/especialidades'));
  Future<Map<String, dynamic>> obtener(String id) async => mapa(await _api.get('/medicos/$id'));
  Future<List<Map<String, dynamic>>> politicas() async => listaDeMapas(await _api.get('/agenda/politicas'));
  Future<Map<String, dynamic>> yo() async => mapa(await _api.get('/medicos/yo'));
  Future<Map<String, dynamic>> actualizar(Map<String, dynamic> datos) async => mapa(await _api.patch('/medicos/yo', data: datos));
  Future<void> horario(Map<String, dynamic> datos) async => _api.put('/agenda/horario', data: datos);
  Future<void> politica(String tipo) async => _api.put('/agenda/politica', data: {'tipo': tipo});

  Future<void> subirCredencial(String tipo, String numero, List<int> bytes, String nombre) async {
    final form = FormData.fromMap({
      'tipo': tipo,
      'numero': numero,
      'archivo': MultipartFile.fromBytes(bytes, filename: nombre, contentType: DioMediaType.parse(tipoMime(nombre))),
    });
    await _api.post('/verificaciones/credenciales', data: form);
  }

  Future<List<Map<String, dynamic>>> pendientes() async => listaDeMapas(await _api.get('/verificaciones/pendientes'));
  Future<void> aprobar(String m, String c) async => _api.post('/verificaciones/$m/credenciales/$c/aprobar');
  Future<void> rechazar(String m, String c, String motivo) async =>
      _api.post('/verificaciones/$m/credenciales/$c/rechazar', data: {'motivo': motivo});
  Future<String> url(String m, String c) async => mapa(await _api.get('/verificaciones/$m/credenciales/$c/archivo'))['url'] as String;
}

/// Tipo MIME a partir de la extensión (JPG, PNG o PDF).
String tipoMime(String nombreArchivo) {
  final ext = nombreArchivo.split('.').last.toLowerCase();
  return switch (ext) { 'pdf' => 'application/pdf', 'png' => 'image/png', _ => 'image/jpeg' };
}

class MedicoMapper {
  static PoliticaCancelacion politica(Map<String, dynamic> j) => PoliticaCancelacion(
        tipo: j['tipo'] as String,
        horasMinimasAviso: (j['horasMinimasAviso'] as num).toInt(),
        porcentajePenalizacion: numero(j['porcentajePenalizacion']),
        descripcion: j['descripcion'] as String? ?? '',
      );

  static Medico desdeJson(Map<String, dynamic> j) => Medico(
        id: j['id'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        especialidades: textos(j['especialidades']),
        tarifa: numero(j['tarifaConsulta']),
        moneda: j['moneda'] as String? ?? 'USD',
        verificado: j['verificado'] as bool? ?? false,
        calificacion: numero(j['calificacionPromedio']),
        totalResenas: (j['totalResenas'] as num?)?.toInt() ?? 0,
        modalidades: textos(j['modalidades']),
        politica: politica(mapa(j['politicaCancelacion'])),
        tieneHorario: j['tieneHorario'] as bool? ?? false,
        direccion: textoOpcional(j['direccionConsultorio']),
        biografia: textoOpcional(j['biografia']),
        estadoVerificacion: textoOpcional(j['estadoVerificacion']),
        credenciales: listaDeMapas(j['credenciales'])
            .map((c) => Credencial(
                  id: c['id'] as String,
                  tipo: c['tipo'] as String,
                  numero: c['numero'] as String,
                  estado: c['estado'] as String,
                  observaciones: textoOpcional(c['observaciones']),
                  enviadaEn: fechaOpcional(c['enviadaEn']),
                ))
            .toList(),
        horario: listaDeMapas(j['horario'])
            .map((b) => BloqueHorario(
                  diaSemana: (b['diaSemana'] as num).toInt(),
                  horaInicio: b['horaInicio'] as String,
                  horaFin: b['horaFin'] as String,
                  duracionCitaMin: (b['duracionCitaMin'] as num).toInt(),
                ))
            .toList(),
      );
}
