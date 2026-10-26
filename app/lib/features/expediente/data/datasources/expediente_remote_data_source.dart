import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/expediente.dart';

class ExpedienteRemoteDataSource {
  const ExpedienteRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> resumen(String id) async => mapa(await _api.get('/expedientes/$id'));
  Future<Map<String, dynamic>> lineaDeTiempo(String id, String? tipo, int pagina) async =>
      mapa(await _api.get('/expedientes/$id/linea-tiempo', query: {'pagina': pagina, 'tamano': 50, if (tipo != null) 'tipo': tipo}));
  Future<Map<String, dynamic>> agregarEvento(String id, NuevoEvento e) async => mapa(await _api.post('/expedientes/$id/eventos', data: {
        'tipo': e.tipo,
        'titulo': e.titulo,
        'resumen': e.resumen,
        'fecha': Formatos.iso(e.fecha),
      }));
  Future<void> antecedentes(String id, List<String> a) async => _api.put('/expedientes/$id/antecedentes', data: {'antecedentes': a});
  Future<String> exportar(String id) async => mapa(await _api.post('/expedientes/$id/exportar'))['url'] as String;

  Future<List<Map<String, dynamic>>> permisos(String id) async => listaDeMapas(await _api.get('/expedientes/$id/permisos'));
  Future<void> conceder(String id, NuevoPermiso p) async => _api.post('/expedientes/$id/permisos', data: {
        'medicoId': p.medicoId,
        'categorias': p.categorias,
        'validoHasta': Formatos.iso(p.validoHasta),
        'escritura': p.escritura,
      });
  Future<void> revocar(String permisoId) async => _api.delete('/expedientes/permisos/$permisoId');
  Future<List<Map<String, dynamic>>> auditoria(String id) async => listaDeMapas(await _api.get('/auditoria/pacientes/$id'));

  Future<List<Map<String, dynamic>>> misPacientes() async => listaDeMapas(await _api.get('/expedientes/medico/pacientes'));
  Future<List<Map<String, dynamic>>> referencias() async => listaDeMapas(await _api.get('/referencias'));
  Future<void> referir(String pacienteId, String destino, String motivo) async =>
      _api.post('/referencias', data: {'pacienteId': pacienteId, 'medicoDestinoId': destino, 'motivo': motivo});
  Future<void> responder(String id, bool aprobar) async => _api.post('/referencias/$id/${aprobar ? 'aprobar' : 'rechazar'}');
}

class ExpedienteMapper {
  static MedicoResumen? medico(dynamic v) {
    if (v == null) return null;
    final j = mapa(v);
    return MedicoResumen(
      id: j['id'] as String,
      nombreCompleto: j['nombreCompleto'] as String? ?? 'Médico',
      especialidad: j['especialidad'] as String? ?? '',
      verificado: j['verificado'] as bool? ?? true,
    );
  }

  static EventoClinico evento(Map<String, dynamic> j) => EventoClinico(
        id: j['id'] as String,
        tipo: j['tipo'] as String,
        categoria: j['categoria'] as String,
        fecha: fecha(j['fecha']),
        titulo: j['titulo'] as String,
        resumen: j['resumen'] as String? ?? '',
        detalles: (j['detalles'] as Map? ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        autoReportado: j['autoReportado'] as bool? ?? false,
        medico: medico(j['medico']),
        documentoOrigenId: textoOpcional(j['documentoOrigenId']),
      );

  static ResumenExpediente resumen(Map<String, dynamic> j) {
    final p = mapa(j['paciente']);
    final a = mapa(j['acceso']);
    return ResumenExpediente(
      id: j['id'] as String,
      pacienteId: p['id'] as String,
      pacienteNombre: p['nombreCompleto'] as String,
      edad: (p['edad'] as num?)?.toInt() ?? 0,
      sexo: p['sexo'] as String? ?? '',
      cedula: textoOpcional(p['cedula']),
      antecedentes: textos(j['antecedentes']),
      acceso: AccesoExpediente(
        esTitular: a['esTitular'] as bool? ?? false,
        categorias: textos(a['categorias']),
        categoriasEscritura: textos(a['categoriasEscritura']),
      ),
    );
  }

  static Permiso permiso(Map<String, dynamic> j) => Permiso(
        id: j['id'] as String,
        categorias: textos(j['categorias']),
        escritura: j['escritura'] as bool? ?? false,
        validoHasta: fecha(j['validoHasta']),
        revocado: j['revocado'] as bool? ?? false,
        vigente: j['vigente'] as bool? ?? false,
        origen: j['origen'] as String? ?? 'PACIENTE',
        medico: medico(j['medico']),
      );

  static Referencia referencia(Map<String, dynamic> j) => Referencia(
        id: j['id'] as String,
        pacienteId: j['pacienteId'] as String,
        pacienteNombre: j['pacienteNombre'] as String? ?? 'Paciente',
        especialidadDestino: j['especialidadDestino'] as String? ?? '',
        motivo: j['motivo'] as String? ?? '',
        estado: j['estado'] as String,
        fecha: fecha(j['fecha']),
        medicoOrigen: medico(j['medicoOrigen']),
        medicoDestino: medico(j['medicoDestino']),
      );

  static PacienteAutorizado pacienteAutorizado(Map<String, dynamic> j) {
    final p = mapa(j['paciente']);
    return PacienteAutorizado(
      pacienteId: p['id'] as String,
      nombre: p['nombreCompleto'] as String,
      edad: (p['edad'] as num?)?.toInt() ?? 0,
      categorias: textos(j['categorias']),
      escritura: j['escritura'] as bool? ?? false,
      validoHasta: fecha(j['validoHasta']),
    );
  }

  static RegistroAcceso acceso(Map<String, dynamic> j) => RegistroAcceso(
        fecha: fecha(j['fecha']),
        accion: j['accion'] as String,
        rolActor: j['rolActor'] as String,
        accesoEmergencia: j['accesoEmergencia'] as bool? ?? false,
      );
}
