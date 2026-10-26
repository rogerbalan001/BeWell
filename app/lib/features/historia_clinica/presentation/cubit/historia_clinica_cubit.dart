import '../../../../core/estado/recurso.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';

/// Historia clínica de un paciente (antecedentes + consultas).
class HistoriaClinicaCubit extends RecursoCubit<HistoriaClinica> {
  HistoriaClinicaCubit(this._obtener);
  final ObtenerHistoriaClinica _obtener;

  String? _pacienteId;

  Future<void> cargar(String pacienteId, {bool silencioso = false}) {
    _pacienteId = pacienteId;
    return ejecutar(() => _obtener(pacienteId), silencioso: silencioso);
  }

  Future<void> recargar() => cargar(_pacienteId!, silencioso: true);
}
