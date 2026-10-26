import '../entities/historia_clinica.dart';
import '../repositories/historia_clinica_repository.dart';

/// HU: historia clínica del paciente (antecedentes + consultas).
class ObtenerHistoriaClinica {
  const ObtenerHistoriaClinica(this._r);
  final HistoriaClinicaRepository _r;
  Future<HistoriaClinica> call(String pacienteId) => _r.obtener(pacienteId);
  Future<String> exportarPdf(String pacienteId) => _r.exportarPdf(pacienteId);
}

/// El paciente (auto-reportado) o un médico autorizado actualiza los antecedentes.
class ActualizarAntecedentesClinicos {
  const ActualizarAntecedentesClinicos(this._r);
  final HistoriaClinicaRepository _r;
  Future<Antecedentes> call(String pacienteId, Antecedentes a) => _r.actualizarAntecedentes(pacienteId, a);
}

/// El médico registra (o corrige dentro de 24 h) la historia de una consulta.
class RegistrarConsultaClinica {
  const RegistrarConsultaClinica(this._r);
  final HistoriaClinicaRepository _r;
  Future<ConsultaClinica> call(String pacienteId, ContenidoConsulta c, {String? citaId}) =>
      _r.registrarConsulta(pacienteId, c, citaId: citaId);
  Future<ConsultaClinica> corregir(String pacienteId, String consultaId, ContenidoConsulta c) =>
      _r.corregirConsulta(pacienteId, consultaId, c);
}
