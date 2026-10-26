import '../../../../core/estado/recurso.dart';
import '../../domain/entities/expediente.dart';
import '../../domain/usecases/expediente_usecases.dart';

class DatosExpediente {
  const DatosExpediente(this.resumen, this.pagina, this.filtro);
  final ResumenExpediente resumen;
  final PaginaEventos pagina;
  final String? filtro;
}

/// Expediente + línea de tiempo filtrable por tipo de evento.
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
