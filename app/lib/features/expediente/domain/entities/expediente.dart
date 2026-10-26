import 'package:equatable/equatable.dart';

/// Secciones del expediente sobre las que el paciente concede permisos.
const categoriasClinicas = <String, String>{
  'CONSULTAS': 'Consultas',
  'DIAGNOSTICOS': 'Diagnósticos',
  'LABORATORIOS': 'Laboratorios y exámenes',
  'CIRUGIAS': 'Cirugías',
  'VACUNAS': 'Vacunas',
  'RECETAS': 'Récipes',
  'SALUD_MENTAL': 'Salud mental',
};

const tiposEvento = <String, String>{
  'CONSULTA': 'Consulta',
  'DIAGNOSTICO': 'Diagnóstico',
  'CIRUGIA': 'Cirugía',
  'VACUNA': 'Vacuna',
  'EXAMEN': 'Examen',
  'SOLICITUD_EXAMEN': 'Orden de exámenes',
  'RECETA': 'Récipe',
  'REFERENCIA': 'Referencia',
  'NOTA_SALUD_MENTAL': 'Salud mental',
};

class MedicoResumen extends Equatable {
  const MedicoResumen({required this.id, required this.nombreCompleto, required this.especialidad, this.verificado = true});
  final String id;
  final String nombreCompleto;
  final String especialidad;
  final bool verificado;
  @override
  List<Object?> get props => [id];
}

class EventoClinico extends Equatable {
  const EventoClinico({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.fecha,
    required this.titulo,
    required this.resumen,
    required this.detalles,
    required this.autoReportado,
    this.medico,
    this.documentoOrigenId,
  });
  final String id;
  final String tipo;
  final String categoria;
  final DateTime fecha;
  final String titulo;
  final String resumen;
  final Map<String, String> detalles;
  final bool autoReportado;
  final MedicoResumen? medico;
  final String? documentoOrigenId;

  String get tipoLegible => tiposEvento[tipo] ?? tipo;

  @override
  List<Object?> get props => [id];
}

class PaginaEventos {
  const PaginaEventos({required this.items, required this.total, required this.categoriasPermitidas, required this.esTitular});
  final List<EventoClinico> items;
  final int total;
  final List<String> categoriasPermitidas;
  final bool esTitular;
}

class AccesoExpediente {
  const AccesoExpediente({required this.esTitular, required this.categorias, required this.categoriasEscritura});
  final bool esTitular;
  final List<String> categorias;
  final List<String> categoriasEscritura;
  bool puedeEscribir(String categoria) => categoriasEscritura.contains(categoria);
}

class ResumenExpediente {
  const ResumenExpediente({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.edad,
    required this.sexo,
    required this.antecedentes,
    required this.acceso,
    this.cedula,
  });
  final String id;
  final String pacienteId;
  final String pacienteNombre;
  final int edad;
  final String sexo;
  final List<String> antecedentes;
  final AccesoExpediente acceso;
  final String? cedula;

  /// Identificador legible del expediente (estilo "EXP-2026-…").
  String get codigo => 'EXP-${id.substring(id.length - 8).toUpperCase()}';
}

class Permiso extends Equatable {
  const Permiso({
    required this.id,
    required this.categorias,
    required this.escritura,
    required this.validoHasta,
    required this.revocado,
    required this.vigente,
    required this.origen,
    this.medico,
  });
  final String id;
  final List<String> categorias;
  final bool escritura;
  final DateTime validoHasta;
  final bool revocado;
  final bool vigente;
  final String origen;
  final MedicoResumen? medico;
  @override
  List<Object?> get props => [id, revocado, vigente];
}

class Referencia extends Equatable {
  const Referencia({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.especialidadDestino,
    required this.motivo,
    required this.estado,
    required this.fecha,
    this.medicoOrigen,
    this.medicoDestino,
  });
  final String id;
  final String pacienteId;
  final String pacienteNombre;
  final String especialidadDestino;
  final String motivo;
  final String estado;
  final DateTime fecha;
  final MedicoResumen? medicoOrigen;
  final MedicoResumen? medicoDestino;

  bool get pendiente => estado == 'PENDIENTE_APROBACION';
  String get estadoLegible => switch (estado) { 'APROBADA' => 'Aprobada', 'RECHAZADA' => 'Rechazada', _ => 'Pendiente de tu aprobación' };
  @override
  List<Object?> get props => [id, estado];
}

class PacienteAutorizado {
  const PacienteAutorizado({required this.pacienteId, required this.nombre, required this.edad, required this.categorias, required this.escritura, required this.validoHasta});
  final String pacienteId;
  final String nombre;
  final int edad;
  final List<String> categorias;
  final bool escritura;
  final DateTime validoHasta;
}

class RegistroAcceso {
  const RegistroAcceso({required this.fecha, required this.accion, required this.rolActor, required this.accesoEmergencia});
  final DateTime fecha;
  final String accion;
  final String rolActor;
  final bool accesoEmergencia;
}

class NuevoEvento {
  const NuevoEvento({required this.tipo, required this.titulo, required this.resumen, required this.fecha});
  final String tipo;
  final String titulo;
  final String resumen;
  final DateTime fecha;
}

class NuevoPermiso {
  const NuevoPermiso({required this.medicoId, required this.categorias, required this.validoHasta, required this.escritura});
  final String medicoId;
  final List<String> categorias;
  final DateTime validoHasta;
  final bool escritura;
}
