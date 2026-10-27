import '../../domain/entities/recordatorio.dart';
import '../../domain/repositories/recordatorios_repository.dart';
import '../datasources/recordatorios_remote_data_source.dart';

class RecordatoriosRepositoryImpl implements RecordatoriosRepository {
  const RecordatoriosRepositoryImpl(this._r);
  final RecordatoriosRemoteDataSource _r;

  @override
  Future<PreferenciasRecordatorio> preferencias() async => RecordatorioMapper.preferencias(await _r.preferencias());

  @override
  Future<PreferenciasRecordatorio> actualizar(PreferenciasRecordatorio p) async => RecordatorioMapper.preferencias(await _r.actualizar(p));

  @override
  Future<List<Recordatorio>> proximos({String? pacienteId}) async => (await _r.proximos(pacienteId)).map(RecordatorioMapper.recordatorio).toList();
}
