import 'package:equatable/equatable.dart';

import '../../../expediente/domain/entities/expediente.dart';

const gruposSanguineos = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// V. Historia personal y social: hábitos, en el orden en que se muestran.
const habitosLegibles = <String, String>{
  'alcohol': 'Alcohol',
  'tabaco': 'Tabaco',
  'cafe': 'Café',
  'drogas': 'Drogas',
  'actividadFisica': 'Ejercicio',
  'alimentacion': 'Nutrición',
  'sueno': 'Sueño',
  'vivienda': 'Vivienda',
};

/// Datos de identificación que no están en el perfil del paciente.
const datosSocialesLegibles = <String, String>{
  'estadoCivil': 'Estado civil',
  'nivelInstruccion': 'Nivel de instrucción',
  'ocupacion': 'Ocupación',
  'procedencia': 'Procedencia',
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

/// Antecedentes de la historia clínica (secciones III a V del modelo integral).
class Antecedentes extends Equatable {
  const Antecedentes({
    this.numeroHistoria,
    this.grupoSanguineo,
    this.datosSociales = const {},
    this.inmunizaciones = const [],
    this.infancia = const [],
    this.alergicos = const [],
    this.patologicos = const [],
    this.quirurgicos = const [],
    this.traumatologicos = const [],
    this.transfusionales = const [],
    this.epidemiologicos = const [],
    this.medicamentosActuales = const [],
    this.familiares = const [],
    this.habitos = const {},
    this.ginecoObstetricos,
    this.actualizadoEn,
    this.actualizadoPorMedico = false,
  });

  final String? numeroHistoria;
  final String? grupoSanguineo;
  final Map<String, String> datosSociales;
  final List<String> inmunizaciones;
  final List<String> infancia;
  final List<String> alergicos;
  final List<String> patologicos;
  final List<String> quirurgicos;
  final List<String> traumatologicos;
  final List<String> transfusionales;
  final List<String> epidemiologicos;
  final List<String> medicamentosActuales;
  final List<String> familiares;
  final Map<String, String> habitos;
  final GinecoObstetricos? ginecoObstetricos;
  final DateTime? actualizadoEn;
  final bool actualizadoPorMedico;

  /// III. Antecedentes personales que son listas, en el orden del modelo.
  Map<String, List<String>> get personales => {
        'Inmunizaciones': inmunizaciones,
        'Enfermedades de la infancia': infancia,
        'Alergias': alergicos,
        'Médicos': patologicos,
        'Quirúrgicos': quirurgicos,
        'Traumatológicos': traumatologicos,
        'Transfusionales': transfusionales,
        'Epidemiológicos': epidemiologicos,
        'Medicamentos actuales': medicamentosActuales,
      };

  bool get vacio =>
      grupoSanguineo == null &&
      datosSociales.isEmpty &&
      personales.values.every((l) => l.isEmpty) &&
      familiares.isEmpty &&
      habitos.isEmpty &&
      ginecoObstetricos == null;

  Map<String, dynamic> aJson() => {
        if (grupoSanguineo != null) 'grupoSanguineo': grupoSanguineo,
        'datosSociales': datosSociales,
        'inmunizaciones': inmunizaciones,
        'infancia': infancia,
        'alergicos': alergicos,
        'patologicos': patologicos,
        'quirurgicos': quirurgicos,
        'traumatologicos': traumatologicos,
        'transfusionales': transfusionales,
        'epidemiologicos': epidemiologicos,
        'medicamentosActuales': medicamentosActuales,
        'familiares': familiares,
        'habitos': habitos,
        if (ginecoObstetricos != null) 'ginecoObstetricos': ginecoObstetricos!.aJson(),
      };

  @override
  List<Object?> get props => [grupoSanguineo, datosSociales, personales, familiares, habitos, ginecoObstetricos, actualizadoEn];
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
    this.circunferenciaAbdominal,
  });

  final String? tensionArterial;
  final double? frecuenciaCardiaca;
  final double? frecuenciaRespiratoria;
  final double? temperatura;
  final double? saturacionOxigeno;
  final double? peso;
  final double? talla;
  final double? circunferenciaAbdominal;

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
      talla == null &&
      circunferenciaAbdominal == null;

  /// Lista "etiqueta valor unidad" para mostrar en chips.
  List<String> get resumen => [
        if (tensionArterial != null) 'PA $tensionArterial mmHg',
        if (frecuenciaCardiaca != null) 'Pulso ${_n(frecuenciaCardiaca!)} ppm',
        if (frecuenciaRespiratoria != null) 'FR ${_n(frecuenciaRespiratoria!)} rpm',
        if (temperatura != null) 'T ${_n(temperatura!)} °C',
        if (saturacionOxigeno != null) 'SpO₂ ${_n(saturacionOxigeno!)} %',
        if (peso != null) 'Peso ${_n(peso!)} kg',
        if (talla != null) 'Talla ${_n(talla!)} cm',
        if (imc != null) 'IMC ${_n(imc!)}',
        if (circunferenciaAbdominal != null) 'C. abd. ${_n(circunferenciaAbdominal!)} cm',
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
        if (circunferenciaAbdominal != null) 'circunferenciaAbdominal': circunferenciaAbdominal,
      };

  @override
  List<Object?> get props => [tensionArterial, frecuenciaCardiaca, frecuenciaRespiratoria, temperatura, saturacionOxigeno, peso, talla, circunferenciaAbdominal];
}

/// Historia de una consulta (secciones I, II y VI a XII del modelo integral).
class ContenidoConsulta extends Equatable {
  const ContenidoConsulta({
    required this.motivoConsulta,
    this.estimuloIatrotropico,
    required this.enfermedadActual,
    this.revisionPorSistemas,
    this.condicionesGenerales,
    this.signosVitales = const SignosVitales(),
    this.examenFisico = '',
    this.listaProblemas = const [],
    required this.impresionDiagnostica,
    this.examenes,
    required this.plan,
    this.indicaciones,
  });

  final String motivoConsulta;
  final String? estimuloIatrotropico;
  final String enfermedadActual;
  final String? revisionPorSistemas;
  final String? condicionesGenerales;
  final SignosVitales signosVitales;
  final String examenFisico;
  final List<String> listaProblemas;
  final List<String> impresionDiagnostica;
  final String? examenes;
  final String plan;
  final String? indicaciones;

  Map<String, dynamic> aJson() {
    bool lleno(String? v) => v != null && v.isNotEmpty;
    return {
      'motivoConsulta': motivoConsulta,
      if (lleno(estimuloIatrotropico)) 'estimuloIatrotropico': estimuloIatrotropico,
      'enfermedadActual': enfermedadActual,
      if (lleno(revisionPorSistemas)) 'revisionPorSistemas': revisionPorSistemas,
      if (lleno(condicionesGenerales)) 'condicionesGenerales': condicionesGenerales,
      'signosVitales': signosVitales.aJson(),
      'examenFisico': examenFisico,
      'listaProblemas': listaProblemas,
      'impresionDiagnostica': impresionDiagnostica,
      if (lleno(examenes)) 'examenes': examenes,
      'plan': plan,
      if (lleno(indicaciones)) 'indicaciones': indicaciones,
    };
  }

  @override
  List<Object?> get props => [
        motivoConsulta,
        estimuloIatrotropico,
        enfermedadActual,
        revisionPorSistemas,
        condicionesGenerales,
        signosVitales,
        examenFisico,
        listaProblemas,
        impresionDiagnostica,
        examenes,
        plan,
        indicaciones,
      ];
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
