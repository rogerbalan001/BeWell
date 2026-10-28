import '../../../../core/estado/recurso.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';

class DatosExamenes {
  const DatosExamenes(this.examenes, this.solicitudes);
  final List<Examen> examenes;
  final List<SolicitudExamen> solicitudes;
}

class ExamenesCubit extends RecursoCubit<DatosExamenes> {
  ExamenesCubit(this.listar);
  final ListarExamenes listar;

  Future<void> cargar(String pacienteId, {bool silencioso = false}) => ejecutar(() async {
        final examenes = await listar(pacienteId);
        final solicitudes = await listar.solicitudes(pacienteId: pacienteId);
        return DatosExamenes(examenes, solicitudes);
      }, silencioso: silencioso);
}

/// Órdenes de exámenes de un paciente, vistas por el médico.
class OrdenesExamenesCubit extends RecursoCubit<List<SolicitudExamen>> {
  OrdenesExamenesCubit(this._gestion);
  final GestionarOrdenesExamen _gestion;

  String? _pacienteId;

  Future<void> cargar(String pacienteId, {bool silencioso = false}) {
    _pacienteId = pacienteId;
    return ejecutar(() => _gestion.listar(pacienteId), silencioso: silencioso);
  }

  /// Devuelve el mensaje de error o `null` si la orden quedó anulada.
  Future<String?> anular(String solicitudId, String motivo) async {
    final error = await intentar(() => _gestion.anular(solicitudId, motivo));
    if (error == null && _pacienteId != null) await cargar(_pacienteId!, silencioso: true);
    return error;
  }
}
