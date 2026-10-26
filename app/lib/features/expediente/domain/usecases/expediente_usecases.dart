import '../entities/expediente.dart';
import '../repositories/expediente_repository.dart';

/// HU: ser dueño de mi expediente y llevarlo de un médico a otro.
class ObtenerExpediente {
  const ObtenerExpediente(this._r);
  final ExpedienteRepository _r;
  Future<ResumenExpediente> call(String pacienteId) => _r.resumen(pacienteId);
  Future<String> exportarPdf(String pacienteId) => _r.exportarPdf(pacienteId);
}

/// HU: línea de tiempo con consultas, diagnósticos, cirugías y vacunas.
class ObtenerLineaDeTiempo {
  const ObtenerLineaDeTiempo(this._r);
  final ExpedienteRepository _r;
  Future<PaginaEventos> call(String pacienteId, {String? tipo, int pagina = 1}) => _r.lineaDeTiempo(pacienteId, tipo: tipo, pagina: pagina);
}

class AgregarInformacionClinica {
  const AgregarInformacionClinica(this._r);
  final ExpedienteRepository _r;
  Future<EventoClinico> call(String pacienteId, NuevoEvento e) => _r.agregarEvento(pacienteId, e);
  Future<void> antecedentes(String pacienteId, List<String> a) => _r.actualizarAntecedentes(pacienteId, a);
}

/// HU: decidir qué médico ve qué parte de mi historial y por cuánto tiempo.
class GestionarPermisos {
  const GestionarPermisos(this._r);
  final ExpedienteRepository _r;
  Future<List<Permiso>> listar(String pacienteId) => _r.permisos(pacienteId);
  Future<void> conceder(String pacienteId, NuevoPermiso p) => _r.concederAcceso(pacienteId, p);
  Future<void> revocar(String permisoId) => _r.revocarAcceso(permisoId);
  Future<List<RegistroAcceso>> auditoria(String pacienteId) => _r.auditoria(pacienteId);
}

class ListarMisPacientes {
  const ListarMisPacientes(this._r);
  final ExpedienteRepository _r;
  Future<List<PacienteAutorizado>> call() => _r.misPacientes();
}

/// HU: referir pacientes a especialistas de la red compartiendo su expediente.
class GestionarReferencias {
  const GestionarReferencias(this._r);
  final ExpedienteRepository _r;
  Future<List<Referencia>> listar() => _r.referencias();
  Future<void> referir(String pacienteId, String medicoDestinoId, String motivo) => _r.referir(pacienteId, medicoDestinoId, motivo);
  Future<void> aprobar(String id) => _r.responderReferencia(id, aprobar: true);
  Future<void> rechazar(String id) => _r.responderReferencia(id, aprobar: false);
}
