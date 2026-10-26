import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../../medicos/data/datasources/medicos_remote_data_source.dart';
import '../../domain/entities/cita.dart';

class CitasRemoteDataSource {
  const CitasRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> disponibilidad(String medicoId, DateTime? desde, int dias) async => listaDeMapas(await _api.get(
        '/citas/disponibilidad',
        query: {'medicoId': medicoId, 'dias': dias, if (desde != null) 'desde': Formatos.iso(desde)},
      ));

  Future<Map<String, dynamic>> agendar(SolicitudCita s) async => mapa(await _api.post('/citas', data: {
        'medicoId': s.medicoId,
        'pacienteId': s.pacienteId,
        'inicio': Formatos.iso(s.inicio),
        'modalidad': s.modalidad,
        'motivo': s.motivo,
      }));

  Future<List<Map<String, dynamic>>> listar(String? pacienteId, List<String>? estados) async => listaDeMapas(await _api.get('/citas', query: {
        if (pacienteId != null) 'pacienteId': pacienteId,
        if (estados != null && estados.isNotEmpty) 'estados': estados.join(','),
      }));

  Future<Map<String, dynamic>> obtener(String id) async => mapa(await _api.get('/citas/$id'));
  Future<Map<String, dynamic>> accion(String id, String accion, [Map<String, dynamic>? data]) async =>
      mapa(await _api.post('/citas/$id/$accion', data: data ?? <String, dynamic>{}));

  Future<Map<String, dynamic>> proponer(PropuestaSeguimiento p) async => mapa(await _api.post('/citas/propuestas', data: {
        'pacienteId': p.pacienteId,
        'inicio': Formatos.iso(p.inicio),
        'modalidad': p.modalidad,
        if (p.medicoId != null) 'medicoId': p.medicoId,
        if (p.citaOrigenId != null) 'citaOrigenId': p.citaOrigenId,
        if (p.referenciaId != null) 'referenciaId': p.referenciaId,
        if (p.motivo != null) 'motivo': p.motivo,
      }));
}

class CitaMapper {
  static Franja franja(Map<String, dynamic> j) => Franja(fecha(j['inicio']), fecha(j['fin']));

  static Cita desdeJson(Map<String, dynamic> j) {
    final medico = mapa(j['medico']);
    final paciente = mapa(j['paciente']);
    final pago = j['pago'] == null ? null : mapa(j['pago']);
    return Cita(
      id: j['id'] as String,
      codigo: j['codigo'] as String? ?? '',
      estado: j['estado'] as String,
      inicio: fecha(j['inicio']),
      fin: fecha(j['fin']),
      modalidad: j['modalidad'] as String,
      motivo: j['motivo'] as String? ?? '',
      monto: numero(j['monto']),
      moneda: j['moneda'] as String? ?? 'USD',
      pacienteId: paciente['id'] as String,
      pacienteNombre: paciente['nombreCompleto'] as String? ?? 'Paciente',
      medicoId: medico['id'] as String,
      medicoNombre: medico['nombreCompleto'] as String? ?? 'Médico',
      especialidad: medico['especialidad'] as String? ?? '',
      direccion: textoOpcional(medico['direccionConsultorio']),
      politica: MedicoMapper.politica(mapa(j['politicaCancelacion'])),
      propuestaPor: textoOpcional(j['propuestaPor']),
      propuestaExpiraEn: fechaOpcional(j['propuestaExpiraEn']),
      parteQueDebeResponder: textoOpcional(j['parteQueDebeResponder']),
      canceladaPor: textoOpcional(j['canceladaPor']),
      motivoCancelacion: textoOpcional(j['motivoCancelacion']),
      atendidaEn: fechaOpcional(j['atendidaEn']),
      citaOrigenId: textoOpcional(j['citaOrigenId']),
      reembolsoSiCancelaAhora: j['reembolsoSiCancelaAhora'] == null ? null : numero(j['reembolsoSiCancelaAhora']),
      pago: pago == null
          ? null
          : PagoResumen(
              estado: pago['estado'] as String,
              monto: numero(pago['monto']),
              montoReembolsado: numero(pago['montoReembolsado']),
              liberarDespuesDe: fechaOpcional(pago['liberarDespuesDe']),
              motivoDisputa: textoOpcional(pago['motivoDisputa']),
            ),
    );
  }
}
