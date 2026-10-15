import '../../../../core/estado/recurso.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';
import '../../domain/entities/cita.dart';
import '../../domain/usecases/citas_usecases.dart';

class DatosHorario {
  const DatosHorario(this.medico, this.franjas);
  final Medico medico;
  final List<Franja> franjas;
}

/// Paso 2: médico elegido + franjas disponibles de los próximos 14 días.
class HorarioCubit extends RecursoCubit<DatosHorario> {
  HorarioCubit(this._medico, this._disponibilidad);
  final ObtenerMedico _medico;
  final ConsultarDisponibilidad _disponibilidad;

  Future<void> cargar(String medicoId) => ejecutar(() async {
        final medico = await _medico(medicoId);
        final franjas = await _disponibilidad(medicoId, dias: 14);
        return DatosHorario(medico, franjas);
      });
}

class MisCitasCubit extends RecursoCubit<List<Cita>> {
  MisCitasCubit(this._listar);
  final ListarCitas _listar;
  Future<void> cargar({String? pacienteId, bool silencioso = false}) => ejecutar(() => _listar(pacienteId: pacienteId), silencioso: silencioso);
}

class CitaDetalleCubit extends RecursoCubit<Cita> {
  CitaDetalleCubit(this._obtener);
  final ObtenerCita _obtener;
  Future<void> cargar(String id, {bool silencioso = false}) => ejecutar(() => _obtener(id), silencioso: silencioso);
}

/// Borrador que viaja del paso 2 (horario) al paso 3 (confirmación).
class BorradorCita {
  const BorradorCita({required this.medico, required this.franja, required this.modalidad, required this.motivo});
  final Medico medico;
  final Franja franja;
  final String modalidad;
  final String motivo;
}
