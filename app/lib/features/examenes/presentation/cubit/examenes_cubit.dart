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
