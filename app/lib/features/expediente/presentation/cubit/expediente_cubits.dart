import '../../../../core/error/failure.dart';
import '../../../../core/estado/recurso.dart';
import '../../domain/entities/expediente.dart';
import '../../domain/usecases/expediente_usecases.dart';

class DatosExpediente {
  const DatosExpediente(this.resumen, this.pagina, this.filtro, {this.paginaActual = 1, this.cargandoMas = false});
  final ResumenExpediente resumen;
  final PaginaEventos pagina;
  final String? filtro;
  final int paginaActual;
  final bool cargandoMas;

  bool get hayMas => pagina.hayMas;
}

/// Expediente + línea de tiempo filtrable por tipo de evento, cargada por páginas.
class ExpedienteCubit extends RecursoCubit<DatosExpediente> {
  ExpedienteCubit(this._resumen, this._linea);
  final ObtenerExpediente _resumen;
  final ObtenerLineaDeTiempo _linea;

  String? _pacienteId;
  String? filtro;

  Future<void> cargar(String pacienteId, {String? tipo, bool silencioso = false}) {
    _pacienteId = pacienteId;
    filtro = tipo;
    return ejecutar(() async {
      final resumen = await _resumen(pacienteId);
      final pagina = await _linea(pacienteId, tipo: tipo);
      return DatosExpediente(resumen, pagina, tipo);
    }, silencioso: silencioso);
  }

  Future<void> filtrar(String? tipo) => cargar(_pacienteId!, tipo: tipo, silencioso: true);
  Future<void> recargar() => cargar(_pacienteId!, tipo: filtro, silencioso: true);

  /// Trae los eventos más antiguos (página siguiente) y los agrega al final.
  /// Si falla, la lista ya cargada se conserva y se devuelve el mensaje de error.
  Future<String?> cargarMas() async {
    final actual = state.datosOpcional;
    if (actual == null || actual.cargandoMas || !actual.hayMas || _pacienteId == null) return null;
    DatosExpediente con({required PaginaEventos pagina, required int numero, required bool cargando}) =>
        DatosExpediente(actual.resumen, pagina, actual.filtro, paginaActual: numero, cargandoMas: cargando);

    emit(RecursoListo(con(pagina: actual.pagina, numero: actual.paginaActual, cargando: true)));
    try {
      final siguiente = await _linea(_pacienteId!, tipo: actual.filtro, pagina: actual.paginaActual + 1);
      if (!isClosed) emit(RecursoListo(con(pagina: actual.pagina.conSiguiente(siguiente), numero: actual.paginaActual + 1, cargando: false)));
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(RecursoListo(con(pagina: actual.pagina, numero: actual.paginaActual, cargando: false)));
      return f.mensaje;
    }
  }
}

class DatosPermisos {
  const DatosPermisos(this.permisos, this.accesos);
  final List<Permiso> permisos;
  final List<RegistroAcceso> accesos;
}

class PermisosCubit extends RecursoCubit<DatosPermisos> {
  PermisosCubit(this.gestion);
  final GestionarPermisos gestion;
  Future<void> cargar(String pacienteId, {bool silencioso = false}) => ejecutar(() async {
        final permisos = await gestion.listar(pacienteId);
        final accesos = await gestion.auditoria(pacienteId);
        return DatosPermisos(permisos, accesos);
      }, silencioso: silencioso);
}

class ReferenciasCubit extends RecursoCubit<List<Referencia>> {
  ReferenciasCubit(this.gestion);
  final GestionarReferencias gestion;
  Future<void> cargar({bool silencioso = false}) => ejecutar(gestion.listar, silencioso: silencioso);
}

class MisPacientesCubit extends RecursoCubit<List<PacienteAutorizado>> {
  MisPacientesCubit(this._listar);
  final ListarMisPacientes _listar;
  Future<void> cargar() => ejecutar(_listar.call);
}
