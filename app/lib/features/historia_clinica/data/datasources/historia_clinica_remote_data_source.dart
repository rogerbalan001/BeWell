import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../../expediente/data/datasources/expediente_remote_data_source.dart';
import '../../../expediente/domain/entities/expediente.dart';
import '../../domain/entities/historia_clinica.dart';

class HistoriaClinicaRemoteDataSource {
  const HistoriaClinicaRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> obtener(String pacienteId) async => mapa(await _api.get('/historias-clinicas/$pacienteId'));

  Future<Map<String, dynamic>> antecedentes(String pacienteId, Antecedentes a) async =>
      mapa(await _api.put('/historias-clinicas/$pacienteId/antecedentes', data: a.aJson()));

  Future<Map<String, dynamic>> registrarConsulta(String pacienteId, ContenidoConsulta c, String? citaId) async =>
      mapa(await _api.post('/historias-clinicas/$pacienteId/consultas', data: {...c.aJson(), if (citaId != null) 'citaId': citaId}));

  Future<Map<String, dynamic>> corregirConsulta(String pacienteId, String consultaId, ContenidoConsulta c) async =>
      mapa(await _api.put('/historias-clinicas/$pacienteId/consultas/$consultaId', data: c.aJson()));

  Future<String> exportar(String pacienteId) async => mapa(await _api.post('/historias-clinicas/$pacienteId/exportar'))['url'] as String;
}

class HistoriaClinicaMapper {
  static double? _num(dynamic v) => v == null ? null : (v as num).toDouble();
  static int? _entero(dynamic v) => v == null ? null : (v as num).toInt();

  static Antecedentes antecedentes(Map<String, dynamic> j) {
    final g = j['ginecoObstetricos'];
    return Antecedentes(
      grupoSanguineo: textoOpcional(j['grupoSanguineo']),
      patologicos: textos(j['patologicos']),
      quirurgicos: textos(j['quirurgicos']),
      alergicos: textos(j['alergicos']),
      medicamentosActuales: textos(j['medicamentosActuales']),
      hospitalizaciones: textos(j['hospitalizaciones']),
      inmunizaciones: textos(j['inmunizaciones']),
      familiares: textos(j['familiares']),
      habitos: (j['habitos'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      ginecoObstetricos: g == null
          ? null
          : GinecoObstetricos(
              menarquia: textoOpcional(g['menarquia']),
              ultimaMenstruacion: textoOpcional(g['ultimaMenstruacion']),
              gestas: _entero(g['gestas']),
              partos: _entero(g['partos']),
              cesareas: _entero(g['cesareas']),
              abortos: _entero(g['abortos']),
              metodoAnticonceptivo: textoOpcional(g['metodoAnticonceptivo']),
            ),
      actualizadoEn: fechaOpcional(j['actualizadoEn']),
      actualizadoPorMedico: j['actualizadoPorMedico'] as bool? ?? false,
    );
  }

  static SignosVitales signos(dynamic v) {
    final j = v == null ? const <String, dynamic>{} : mapa(v);
    return SignosVitales(
      tensionArterial: textoOpcional(j['tensionArterial']),
      frecuenciaCardiaca: _num(j['frecuenciaCardiaca']),
      frecuenciaRespiratoria: _num(j['frecuenciaRespiratoria']),
      temperatura: _num(j['temperatura']),
      saturacionOxigeno: _num(j['saturacionOxigeno']),
      peso: _num(j['peso']),
      talla: _num(j['talla']),
    );
  }

  static ConsultaClinica consulta(Map<String, dynamic> j) => ConsultaClinica(
        id: j['id'] as String,
        fecha: fecha(j['fecha']),
        citaId: textoOpcional(j['citaId']),
        medico: ExpedienteMapper.medico(j['medico']),
        editable: j['editable'] as bool? ?? false,
        contenido: ContenidoConsulta(
          motivoConsulta: j['motivoConsulta'] as String? ?? '',
          enfermedadActual: j['enfermedadActual'] as String? ?? '',
          revisionPorSistemas: textoOpcional(j['revisionPorSistemas']),
          signosVitales: signos(j['signosVitales']),
          examenFisico: j['examenFisico'] as String? ?? '',
          impresionDiagnostica: textos(j['impresionDiagnostica']),
          plan: j['plan'] as String? ?? '',
          indicaciones: textoOpcional(j['indicaciones']),
        ),
      );

  static HistoriaClinica historia(Map<String, dynamic> j) {
    final p = mapa(j['paciente']);
    final a = mapa(j['acceso']);
    return HistoriaClinica(
      pacienteId: p['id'] as String,
      pacienteNombre: p['nombreCompleto'] as String,
      edad: (p['edad'] as num?)?.toInt() ?? 0,
      sexo: p['sexo'] as String? ?? '',
      cedula: textoOpcional(p['cedula']),
      acceso: AccesoExpediente(
        esTitular: a['esTitular'] as bool? ?? false,
        categorias: textos(a['categorias']),
        categoriasEscritura: textos(a['categoriasEscritura']),
      ),
      antecedentes: j['antecedentes'] == null ? null : antecedentes(mapa(j['antecedentes'])),
      consultas: listaDeMapas(j['consultas']).map(consulta).toList(),
      puedeEditarAntecedentes: j['puedeEditarAntecedentes'] as bool? ?? false,
      puedeRegistrarConsulta: j['puedeRegistrarConsulta'] as bool? ?? false,
    );
  }
}
