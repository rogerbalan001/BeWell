import '../entities/recordatorio.dart';

abstract class RecordatoriosRepository {
  Future<PreferenciasRecordatorio> preferencias();
  Future<PreferenciasRecordatorio> actualizar(PreferenciasRecordatorio preferencias);
  Future<List<Recordatorio>> proximos({String? pacienteId});
}
