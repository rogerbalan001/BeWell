import '../../../../core/estado/recurso.dart';
import '../../domain/entities/recordatorio.dart';
import '../../domain/usecases/recordatorios_usecases.dart';

class DatosRecordatorios {
  const DatosRecordatorios(this.preferencias, this.proximos);
  final PreferenciasRecordatorio preferencias;
  final List<Recordatorio> proximos;
}

class RecordatoriosCubit extends RecursoCubit<DatosRecordatorios> {
  RecordatoriosCubit(this._gestion);
  final GestionarRecordatorios _gestion;

  Future<void> cargar({bool silencioso = false}) => ejecutar(() async {
        final preferencias = await _gestion.preferencias();
        final proximos = await _gestion.proximos();
        return DatosRecordatorios(preferencias, proximos);
      }, silencioso: silencioso);

  /// Activa o desactiva un tipo. Devuelve el mensaje de error o `null`.
  Future<String?> cambiar(TipoRecordatorio tipo, bool activo) async {
    final actual = state.datosOpcional;
    if (actual == null) return null;
    final nuevas = switch (tipo) {
      TipoRecordatorio.citas => actual.preferencias.copiarCon(citas: activo),
      TipoRecordatorio.medicamentos => actual.preferencias.copiarCon(medicamentos: activo),
      TipoRecordatorio.examenes => actual.preferencias.copiarCon(examenes: activo),
    };
    final error = await intentar(() => _gestion.actualizar(nuevas));
    await cargar(silencioso: true);
    return error;
  }
}
