import '../../domain/entities/historia_clinica.dart';
import '../../domain/repositories/historia_clinica_repository.dart';
import '../datasources/historia_clinica_remote_data_source.dart';

class HistoriaClinicaRepositoryImpl implements HistoriaClinicaRepository {
  const HistoriaClinicaRepositoryImpl(this._r);
  final HistoriaClinicaRemoteDataSource _r;

  @override
  Future<HistoriaClinica> obtener(String pacienteId) async => HistoriaClinicaMapper.historia(await _r.obtener(pacienteId));

  @override
  Future<Antecedentes> actualizarAntecedentes(String pacienteId, Antecedentes antecedentes) async =>
      HistoriaClinicaMapper.antecedentes(await _r.antecedentes(pacienteId, antecedentes));

  @override
  Future<ConsultaClinica> registrarConsulta(String pacienteId, ContenidoConsulta contenido, {String? citaId}) async =>
      HistoriaClinicaMapper.consulta(await _r.registrarConsulta(pacienteId, contenido, citaId));

  @override
  Future<ConsultaClinica> corregirConsulta(String pacienteId, String consultaId, ContenidoConsulta contenido) async =>
      HistoriaClinicaMapper.consulta(await _r.corregirConsulta(pacienteId, consultaId, contenido));

  @override
  Future<String> exportarPdf(String pacienteId) => _r.exportar(pacienteId);
}
