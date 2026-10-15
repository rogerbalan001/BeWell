import '../entities/cita.dart';
import '../repositories/citas_repository.dart';

class ConsultarDisponibilidad {
  const ConsultarDisponibilidad(this._r);
  final CitasRepository _r;
  Future<List<Franja>> call(String medicoId, {DateTime? desde, int dias = 14}) => _r.disponibilidad(medicoId, desde: desde, dias: dias);
}

/// HU: agendar una consulta con el especialista elegido (el cobro se retiene al confirmar).
class AgendarCita {
  const AgendarCita(this._r);
  final CitasRepository _r;
  Future<Cita> call(SolicitudCita s) => _r.agendar(s);
}

class ListarCitas {
  const ListarCitas(this._r);
  final CitasRepository _r;
  Future<List<Cita>> call({String? pacienteId, List<String>? estados}) => _r.listar(pacienteId: pacienteId, estados: estados);
}

class ObtenerCita {
  const ObtenerCita(this._r);
  final CitasRepository _r;
  Future<Cita> call(String id) => _r.obtener(id);
}

/// Devuelve la cita cancelada y el monto reembolsado según la política aplicada.
class CancelarCita {
  const CancelarCita(this._r);
  final CitasRepository _r;
  Future<(Cita, double)> call(String id, String motivo) => _r.cancelar(id, motivo);
}

class MarcarCitaAtendida {
  const MarcarCitaAtendida(this._r);
  final CitasRepository _r;
  Future<Cita> call(String id, {String? notaClinica, List<String> diagnosticos = const []}) =>
      _r.marcarAtendida(id, notaClinica: notaClinica, diagnosticos: diagnosticos);
  Future<Cita> noAsistio(String id) => _r.marcarNoAsistio(id);
}

class ReportarProblemaPago {
  const ReportarProblemaPago(this._r);
  final CitasRepository _r;
  Future<Cita> call(String id, String motivo) => _r.reportarProblema(id, motivo);
}

/// HU: consulta de seguimiento aceptada por ambas partes.
class ProponerSeguimiento {
  const ProponerSeguimiento(this._r);
  final CitasRepository _r;
  Future<Cita> call(PropuestaSeguimiento p) => _r.proponer(p);
}

class ResponderPropuesta {
  const ResponderPropuesta(this._r);
  final CitasRepository _r;
  Future<Cita> aceptar(String id) => _r.responderPropuesta(id, aceptar: true);
  Future<Cita> rechazar(String id) => _r.responderPropuesta(id, aceptar: false);
}
