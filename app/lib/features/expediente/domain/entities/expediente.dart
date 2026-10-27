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

  /// Detalles en palabras del paciente: sin claves técnicas ni datos internos.
  List<(String, String)> get detallesLegibles => [
        for (final d in detalles.entries)
          if (_etiquetasDetalle.containsKey(d.key) && d.value.trim().isNotEmpty) (_etiquetasDetalle[d.key]!, _valorLegible(d.key, d.value)),
      ];

  /// Estado de una orden de exámenes ("Pendiente", "Resultados cargados", "Anulada"), si aplica.
  String? get estadoOrden => tipo == 'SOLICITUD_EXAMEN' && detalles['estado'] != null ? _valorLegible('estado', detalles['estado']!) : null;

  @override
  List<Object?> get props => [id];
}

/// Claves de `detalles` que se muestran y su etiqueta. Las que no están (autoReportado,
/// historiaClinica…) son de uso interno y no se muestran.
const _etiquetasDetalle = <String, String>{
  'estado': 'Estado de la orden',
  'motivoAnulacion': 'Motivo de la anulación',
  'estadoExtraccion': 'Lectura de valores',
  'tipoMime': 'Archivo',
  'codigoVerificacion': 'Código de verificación',
  'modalidad': 'Modalidad',
  'motivo': 'Motivo de consulta',
  'medicoDestino': 'Referido a',
  'especialidadDestino': 'Especialidad',
};

String _valorLegible(String clave, String valor) => switch ((clave, valor)) {
      ('estado', 'PENDIENTE') => 'Pendiente',
      ('estado', 'COMPLETADA') => 'Resultados cargados',
      ('estado', 'ANULADA') => 'Anulada',
      ('estadoExtraccion', 'EXTRAIDO') => 'Valores detectados, por revisar',
      ('estadoExtraccion', 'CONFIRMADO') => 'Valores confirmados',
      ('estadoExtraccion', 'NO_RECONOCIDO') => 'Guardado como adjunto',
      ('tipoMime', 'application/pdf') => 'PDF',
      ('tipoMime', _) when valor.startsWith('image/') => 'Imagen',
      ('modalidad', 'PRESENCIAL') => 'Presencial',
      ('modalidad', 'VIRTUAL') => 'En línea',
      _ => valor,
    };

class PaginaEventos {
  const PaginaEventos({required this.items, required this.total, required this.categoriasPermitidas, required this.esTitular});
  final List<EventoClinico> items;
  final int total;
  final List<String> categoriasPermitidas;
  final bool esTitular;

  /// Quedan eventos más antiguos por cargar.
  bool get hayMas => items.length < total;

  /// Agrega la página siguiente al final (los eventos vienen del más reciente al más antiguo).
  PaginaEventos conSiguiente(PaginaEventos siguiente) => PaginaEventos(
        items: [...items, ...siguiente.items.where((e) => !items.any((x) => x.id == e.id))],
        total: siguiente.total,
        categoriasPermitidas: categoriasPermitidas,
        esTitular: esTitular,
      );
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
