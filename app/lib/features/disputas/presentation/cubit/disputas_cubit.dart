import '../../../../core/error/failure.dart';
import '../../../../core/estado/recurso.dart';
import '../../domain/entities/disputa.dart';
import '../../domain/usecases/disputas_usecases.dart';

/// Lista de disputas abiertas y la acción del administrador sobre cada una.
class DisputasCubit extends RecursoCubit<List<Disputa>> {
  DisputasCubit(this._disputas);
  final GestionarDisputas _disputas;

  Future<void> cargar({bool silencioso = false}) => ejecutar(_disputas.listar, silencioso: silencioso);

  /// Resuelve la disputa y la quita de la lista. Devuelve el error, o null si salió bien.
  Future<String?> resolver(Disputa disputa, AccionDisputa accion, {String? nota}) async {
    try {
      await _disputas.resolver(disputa.pagoId, accion, nota: nota);
      final actuales = state.datosOpcional ?? const <Disputa>[];
      emit(RecursoListo(actuales.where((d) => d.pagoId != disputa.pagoId).toList(), version: actuales.length));
      return null;
    } on Failure catch (f) {
      return f.mensaje;
    } catch (e) {
      return 'Ocurrió un error inesperado: $e';
    }
  }
}
