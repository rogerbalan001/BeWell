import 'package:equatable/equatable.dart';

import '../../../expediente/domain/entities/expediente.dart';

const gruposSanguineos = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Etiquetas de los hábitos psicobiológicos, en el orden en que se muestran.
const habitosLegibles = <String, String>{
  'tabaco': 'Tabaco',
  'alcohol': 'Alcohol',
  'drogas': 'Otras sustancias',
  'actividadFisica': 'Actividad física',
  'alimentacion': 'Alimentación',
  'sueno': 'Sueño',
};

class GinecoObstetricos extends Equatable {
  const GinecoObstetricos({
    this.menarquia,
    this.ultimaMenstruacion,
    this.gestas,
    this.partos,
    this.cesareas,
    this.abortos,
    this.metodoAnticonceptivo,
  });
  final String? menarquia;
  final String? ultimaMenstruacion;
  final int? gestas;
  final int? partos;
  final int? cesareas;
  final int? abortos;
  final String? metodoAnticonceptivo;

  /// Fórmula obstétrica abreviada, p. ej. "G2 P1 C1 A0".
  String get formula => 'G${gestas ?? 0} P${partos ?? 0} C${cesareas ?? 0} A${abortos ?? 0}';

  Map<String, dynamic> aJson() => {
        if (menarquia != null) 'menarquia': menarquia,
        if (ultimaMenstruacion != null) 'ultimaMenstruacion': ultimaMenstruacion,
        if (gestas != null) 'gestas': gestas,
        if (partos != null) 'partos': partos,
        if (cesareas != null) 'cesareas': cesareas,
        if (abortos != null) 'abortos': abortos,
        if (metodoAnticonceptivo != null) 'metodoAnticonceptivo': metodoAnticonceptivo,
      };

  @override
  List<Object?> get props => [menarquia, ultimaMenstruacion, gestas, partos, cesareas, abortos, metodoAnticonceptivo];
}

/// Antecedentes de la historia clínica (anamnesis remota del paciente).
class Antecedentes extends Equatable {
  const Antecedentes({
    this.grupoSanguineo,
    this.patologicos = const [],
    this.quirurgicos = const [],
    this.alergicos = const [],
    this.medicamentosActuales = const [],
    this.hospitalizaciones = const [],
    this.inmunizaciones = const [],
    this.familiares = const [],
    this.habitos = const {},
    this.ginecoObstetricos,
    this.actualizadoEn,
    this.actualizadoPorMedico = false,
  });

  final String? grupoSanguineo;
  final List<String> patologicos;
  final List<String> quirurgicos;
  final List<String> alergicos;
  final List<String> medicamentosActuales;
  final List<String> hospitalizaciones;
  final List<String> inmunizaciones;
  final List<String> familiares;
  final Map<String, String> habitos;
  final GinecoObstetricos? ginecoObstetricos;
  final DateTime? actualizadoEn;
  final bool actualizadoPorMedico;

  bool get vacio =>
      grupoSanguineo == null &&
      patologicos.isEmpty &&
      quirurgicos.isEmpty &&
      alergicos.isEmpty &&
      medicamentosActuales.isEmpty &&
      hospitalizaciones.isEmpty &&
      inmunizaciones.isEmpty &&
      familiares.isEmpty &&
      habitos.isEmpty &&
      ginecoObstetricos == null;

  Map<String, dynamic> aJson() => {
        if (grupoSanguineo != null) 'grupoSanguineo': grupoSanguineo,
        'patologicos': patologicos,
        'quirurgicos': quirurgicos,
        'alergicos': alergicos,
        'medicamentosActuales': medicamentosActuales,
        'hospitalizaciones': hospitalizaciones,
        'inmunizaciones': inmunizaciones,
        'familiares': familiares,
        'habitos': habitos,
        if (ginecoObstetricos != null) 'ginecoObstetricos': ginecoObstetricos!.aJson(),
      };

  @override
  List<Object?> get props => [
        grupoSanguineo,
        patologicos,
        quirurgicos,
        alergicos,
        medicamentosActuales,
        hospitalizaciones,
        inmunizaciones,
        familiares,
        habitos,
        ginecoObstetricos,
        actualizadoEn,
      ];
}

class SignosVitales extends Equatable {
  const SignosVitales({
    this.tensionArterial,
    this.frecuenciaCardiaca,
    this.frecuenciaRespiratoria,
    this.temperatura,
    this.saturacionOxigeno,
    this.peso,
    this.talla,
  });

  final String? tensionArterial;
  final double? frecuenciaCardiaca;
  final double? frecuenciaRespiratoria;
  final double? temperatura;
  final double? saturacionOxigeno;
  final double? peso;
  final double? talla;

  /// Índice de masa corporal (kg/m²) con un decimal.
  double? get imc {
    if (peso == null || talla == null || talla == 0) return null;
    final metros = talla! / 100;
    return (peso! / (metros * metros) * 10).roundToDouble() / 10;
  }

  bool get vacio =>
      tensionArterial == null &&
      frecuenciaCardiaca == null &&
      frecuenciaRespiratoria == null &&
      temperatura == null &&
      saturacionOxigeno == null &&
      peso == null &&
      talla == null;

  /// Lista "etiqueta valor unidad" para mostrar en chips.
  List<String> get resumen => [
        if (tensionArterial != null) 'TA $tensionArterial mmHg',
        if (frecuenciaCardiaca != null) 'FC ${_n(frecuenciaCardiaca!)} lpm',
        if (frecuenciaRespiratoria != null) 'FR ${_n(frecuenciaRespiratoria!)} rpm',
        if (temperatura != null) 'T ${_n(temperatura!)} °C',
        if (saturacionOxigeno != null) 'SpO₂ ${_n(saturacionOxigeno!)} %',
        if (peso != null) 'Peso ${_n(peso!)} kg',
        if (talla != null) 'Talla ${_n(talla!)} cm',
        if (imc != null) 'IMC ${_n(imc!)}',
      ];

  static String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Map<String, dynamic> aJson() => {
        if (tensionArterial != null) 'tensionArterial': tensionArterial,
        if (frecuenciaCardiaca != null) 'frecuenciaCardiaca': frecuenciaCardiaca,
        if (frecuenciaRespiratoria != null) 'frecuenciaRespiratoria': frecuenciaRespiratoria,
        if (temperatura != null) 'temperatura': temperatura,
        if (saturacionOxigeno != null) 'saturacionOxigeno': saturacionOxigeno,
        if (peso != null) 'peso': peso,
        if (talla != null) 'talla': talla,
      };

  @override
  List<Object?> get props => [tensionArterial, frecuenciaCardiaca, frecuenciaRespiratoria, temperatura, saturacionOxigeno, peso, talla];
}

/// Contenido de la historia de una consulta (lo que escribe el médico).
class ContenidoConsulta extends Equatable {
  const ContenidoConsulta({
    required this.motivoConsulta,
    required this.enfermedadActual,
    this.revisionPorSistemas,
    this.signosVitales = const SignosVitales(),
    this.examenFisico = '',
    required this.impresionDiagnostica,
    required this.plan,
    this.indicaciones,
  });

  final String motivoConsulta;
  final String enfermedadActual;
  final String? revisionPorSistemas;
  final SignosVitales signosVitales;
  final String examenFisico;
  final List<String> impresionDiagnostica;
  final String plan;
  final String? indicaciones;

  Map<String, dynamic> aJson() => {
        'motivoConsulta': motivoConsulta,
        'enfermedadActual': enfermedadActual,
        if (revisionPorSistemas != null && revisionPorSistemas!.isNotEmpty) 'revisionPorSistemas': revisionPorSistemas,
        'signosVitales': signosVitales.aJson(),
        'examenFisico': examenFisico,
        'impresionDiagnostica': impresionDiagnostica,
        'plan': plan,
        if (indicaciones != null && indicaciones!.isNotEmpty) 'indicaciones': indicaciones,
      };

  @override
  List<Object?> get props => [motivoConsulta, enfermedadActual, revisionPorSistemas, signosVitales, examenFisico, impresionDiagnostica, plan, indicaciones];
}

/// Historia clínica de un encuentro médico.
class ConsultaClinica extends Equatable {
  const ConsultaClinica({
    required this.id,
    required this.fecha,
    required this.contenido,
    required this.editable,
    this.citaId,
    this.medico,
  });

  final String id;
  final DateTime fecha;
  final ContenidoConsulta contenido;
  final bool editable;
  final String? citaId;
  final MedicoResumen? medico;

  @override
  List<Object?> get props => [id, fecha, contenido, editable];
}

class HistoriaClinica {
  const HistoriaClinica({
    required this.pacienteId,
    required this.pacienteNombre,
    required this.edad,
    required this.sexo,
    required this.acceso,
    required this.antecedentes,
    required this.consultas,
    required this.puedeEditarAntecedentes,
    required this.puedeRegistrarConsulta,
    this.cedula,
  });

  final String pacienteId;
  final String pacienteNombre;
  final int edad;
  final String sexo;
  final String? cedula;
  final AccesoExpediente acceso;

  /// null si el usuario no tiene acceso a la sección de antecedentes.
  final Antecedentes? antecedentes;
  final List<ConsultaClinica> consultas;
  final bool puedeEditarAntecedentes;
  final bool puedeRegistrarConsulta;

  bool get esFemenino => sexo == 'F';
  bool get veConsultas => acceso.categorias.contains('CONSULTAS');
}
