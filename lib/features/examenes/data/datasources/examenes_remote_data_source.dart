import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../../expediente/data/datasources/expediente_remote_data_source.dart';
import '../../../medicos/data/datasources/medicos_remote_data_source.dart';
import '../../domain/entities/examen.dart';

class ExamenesRemoteDataSource {
  const ExamenesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listar(String pacienteId) async => listaDeMapas(await _api.get('/examenes', query: {'pacienteId': pacienteId}));
  Future<List<Map<String, dynamic>>> solicitudes(String? pacienteId) async =>
      listaDeMapas(await _api.get('/examenes/solicitudes', query: {if (pacienteId != null) 'pacienteId': pacienteId}));
  Future<List<Map<String, dynamic>>> catalogo() async => listaDeMapas(await _api.get('/examenes/catalogo'));

  Future<Map<String, dynamic>> subir(String pacienteId, String titulo, ArchivoExamen archivo, String? solicitudId, DateTime? fecha) async {
    final form = FormData.fromMap({
      'pacienteId': pacienteId,
      'titulo': titulo,
      if (solicitudId != null) 'solicitudId': solicitudId,
      if (fecha != null) 'fechaExamen': Formatos.iso(fecha),
      'archivo': MultipartFile.fromBytes(archivo.bytes, filename: archivo.nombre, contentType: DioMediaType.parse(tipoMime(archivo.nombre))),
    });
    return mapa(await _api.post('/examenes', data: form));
  }

  Future<Map<String, dynamic>> confirmar(String id, List<ResultadoAnalito> r) async =>
      mapa(await _api.put('/examenes/$id/resultados', data: {'resultados': r.map((x) => x.aJson()).toList()}));
  Future<Map<String, dynamic>> validar(String id) async => mapa(await _api.post('/examenes/$id/validar'));
  Future<String> url(String id) async => mapa(await _api.get('/examenes/$id/archivo'))['url'] as String;
  Future<Map<String, dynamic>> solicitar(Map<String, dynamic> datos) async => mapa(await _api.post('/examenes/solicitudes', data: datos));
}

class ExamenMapper {
  static Examen examen(Map<String, dynamic> j) => Examen(
        id: j['id'] as String,
        pacienteId: j['pacienteId'] as String,
        titulo: j['titulo'] as String,
        tipoMime: j['tipoMime'] as String,
        nombreArchivo: j['nombreArchivo'] as String,
        estadoExtraccion: j['estadoExtraccion'] as String,
        validadoPorMedico: j['validadoPorMedico'] as bool? ?? false,
        cargadoEn: fecha(j['cargadoEn']),
        solicitudId: textoOpcional(j['solicitudId']),
        fechaExamen: fechaOpcional(j['fechaExamen']),
        resultados: listaDeMapas(j['resultados'])
            .map((r) => ResultadoAnalito(
                  analito: r['analito'] as String,
                  valor: r['valor'].toString(),
                  unidad: textoOpcional(r['unidad']),
                  rangoReferencia: textoOpcional(r['rangoReferencia']),
                  confianzaOcr: r['confianzaOcr'] == null ? null : numero(r['confianzaOcr']),
                  validadoPorMedico: r['validadoPorMedico'] as bool? ?? false,
                ))
            .toList(),
      );

  static SolicitudExamen solicitud(Map<String, dynamic> j) => SolicitudExamen(
        id: j['id'] as String,
        pacienteId: j['pacienteId'] as String,
        examenes: textos(j['examenes']),
        indicaciones: j['indicaciones'] as String? ?? '',
        estado: j['estado'] as String,
        creadaEn: fecha(j['creadaEn']),
        medico: ExpedienteMapper.medico(j['medico']),
        citaId: textoOpcional(j['citaId']),
      );
}
