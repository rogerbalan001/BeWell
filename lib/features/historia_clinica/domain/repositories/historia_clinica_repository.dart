import '../entities/historia_clinica.dart';

abstract class HistoriaClinicaRepository {
  Future<HistoriaClinica> obtener(String pacienteId);
  Future<Antecedentes> actualizarAntecedentes(String pacienteId, Antecedentes antecedentes);
  Future<ConsultaClinica> registrarConsulta(String pacienteId, ContenidoConsulta contenido, {String? citaId});
  Future<ConsultaClinica> corregirConsulta(String pacienteId, String consultaId, ContenidoConsulta contenido);
  Future<String> exportarPdf(String pacienteId);
}
