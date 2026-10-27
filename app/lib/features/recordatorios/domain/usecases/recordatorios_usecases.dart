import '../entities/recordatorio.dart';
import '../repositories/recordatorios_repository.dart';

/// HU-5: el paciente activa o desactiva cada tipo de recordatorio y ve los próximos.
class GestionarRecordatorios {
  const GestionarRecordatorios(this._r);
  final RecordatoriosRepository _r;

  Future<PreferenciasRecordatorio> preferencias() => _r.preferencias();
  Future<PreferenciasRecordatorio> actualizar(PreferenciasRecordatorio p) => _r.actualizar(p);
  Future<List<Recordatorio>> proximos({String? pacienteId}) => _r.proximos(pacienteId: pacienteId);
}
