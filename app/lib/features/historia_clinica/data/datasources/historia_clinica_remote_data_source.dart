import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../../expediente/data/datasources/expediente_remote_data_source.dart';
import '../../../expediente/domain/entities/expediente.dart';
import '../../domain/entities/catalogo_historia.dart';
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
  static Map<String, String> _textos(dynamic v) => (v as Map? ?? const {}).map((k, x) => MapEntry(k.toString(), x.toString()));
  static Map<String, List<String>> _listas(dynamic v) {
    // Historias anteriores guardaban los familiares como una sola lista.
    if (v is List) return v.isEmpty ? const {} : {'otros': textos(v)};
    return (v as Map? ?? const {}).map((k, x) => MapEntry(k.toString(), textos(x)));
  }

  static Antecedentes antecedentes(Map<String, dynamic> j) {
    final g = j['ginecoObstetricos'];
    return Antecedentes(
      numeroHistoria: textoOpcional(j['numeroHistoria']),
      grupoSanguineo: textoOpcional(j['grupoSanguineo']),
      datosSociales: _textos(j['datosSociales']),
      personales: {for (final (_, c) in antecedentesPersonales) c.clave: textos(j[c.clave])},
      familiares: _listas(j['familiares']),
      habitos: _textos(j['habitos']),
      medicamentosActuales: textos(j['medicamentosActuales']),
      ginecoObstetricos: g == null
          ? null
          : GinecoObstetricos(
              menarquia: textoOpcional(g['menarquia']),
              ultimaMenstruacion: textoOpcional(g['ultimaMenstruacion']),
              gestas: _entero(g['gestas']),
              partos: _entero(g['partos']),
              cesareas: _entero(g['cesareas']),
              abortos: _entero(g['abortos']),
              perdidasFetales: _entero(g['perdidasFetales']),
              eclampsia: textoOpcional(g['eclampsia']),
              menopausia: textoOpcional(g['menopausia']),
              trastornosMenstruales: textoOpcional(g['trastornosMenstruales']),
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
      tensionArterialAcostado: textoOpcional(j['tensionArterialAcostado']),
      tensionArterialDePie: textoOpcional(j['tensionArterialDePie']),
      frecuenciaCardiaca: _num(j['frecuenciaCardiaca']),
      frecuenciaRespiratoria: _num(j['frecuenciaRespiratoria']),
      temperatura: _num(j['temperatura']),
      saturacionOxigeno: _num(j['saturacionOxigeno']),
      peso: _num(j['peso']),
      talla: _num(j['talla']),
      circunferenciaAbdominal: _num(j['circunferenciaAbdominal']),
    );
  }

  static ConsultaClinica consulta(Map<String, dynamic> j) {
    final examenes = j['examenes'];
    return ConsultaClinica(
      id: j['id'] as String,
      fecha: fecha(j['fecha']),
      creadaEn: fechaOpcional(j['creadaEn']),
      citaId: textoOpcional(j['citaId']),
      medico: ExpedienteMapper.medico(j['medico']),
      editable: j['editable'] as bool? ?? false,
      contenido: ContenidoConsulta(
        motivoConsulta: j['motivoConsulta'] as String? ?? '',
        estimuloIatrotropico: textoOpcional(j['estimuloIatrotropico']),
        enfermedadActual: j['enfermedadActual'] as String? ?? '',
        revisionSistemas: _textos(j['revisionSistemas']),
        revisionPorSistemas: textoOpcional(j['revisionPorSistemas']),
        condicionesGenerales: textoOpcional(j['condicionesGenerales']),
        signosVitales: signos(j['signosVitales']),
        examenRegiones: _textos(j['examenRegiones']),
        examenFisico: j['examenFisico'] as String? ?? '',
        resumenDatosPositivos: textoOpcional(j['resumenDatosPositivos']),
        listaProblemas: textos(j['listaProblemas']),
        consentimientoInformado: j['consentimientoInformado'] as bool? ?? false,
        impresionDiagnostica: textos(j['impresionDiagnostica']),
        // Historias anteriores guardaban los exámenes como un solo texto.
        examenes: examenes is String ? (examenes.isEmpty ? const {} : {'otros': examenes}) : _textos(examenes),
        planDiagnostico: textoOpcional(j['planDiagnostico']),
        planPreventivo: textoOpcional(j['planPreventivo']),
        plan: j['plan'] as String? ?? '',
        indicaciones: textoOpcional(j['indicaciones']),
      ),
    );
  }

  static HistoriaClinica historia(Map<String, dynamic> j) {
    final p = mapa(j['paciente']);
    final a = mapa(j['acceso']);
    return HistoriaClinica(
      pacienteId: p['id'] as String,
      pacienteNombre: p['nombreCompleto'] as String,
      nombres: textoOpcional(p['nombres']),
      apellidos: textoOpcional(p['apellidos']),
      fechaNacimiento: p['fechaNacimiento'] == null ? null : DateTime.tryParse(p['fechaNacimiento'] as String),
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
