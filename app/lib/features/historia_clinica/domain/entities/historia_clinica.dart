import 'package:equatable/equatable.dart';

import '../../../expediente/domain/entities/expediente.dart';

const gruposSanguineos = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// III.10 Antecedentes ginecobstétricos.
class GinecoObstetricos extends Equatable {
  const GinecoObstetricos({
    this.menarquia,
    this.ultimaMenstruacion,
    this.gestas,
    this.partos,
    this.cesareas,
    this.abortos,
    this.perdidasFetales,
    this.eclampsia,
    this.menopausia,
    this.trastornosMenstruales,
    this.metodoAnticonceptivo,
  });
  final String? menarquia;
  final String? ultimaMenstruacion;
  final int? gestas;
  final int? partos;
  final int? cesareas;
  final int? abortos;
  final int? perdidasFetales;
  final String? eclampsia;
  final String? menopausia;
  final String? trastornosMenstruales;
  final String? metodoAnticonceptivo;

  /// Fórmula obstétrica abreviada, p. ej. "G2 P1 C1 A0".
  String get formula => 'G${gestas ?? 0} P${partos ?? 0} C${cesareas ?? 0} A${abortos ?? 0}';

  /// Pares etiqueta / valor que tienen dato, en el orden del modelo.
  List<(String, String)> get detalle => [
        if (menarquia != null) ('Menarquia', menarquia!),
        if (ultimaMenstruacion != null) ('FUM', ultimaMenstruacion!),
        if (trastornosMenstruales != null) ('Trastornos menstruales', trastornosMenstruales!),
        if (perdidasFetales != null) ('Pérdidas fetales', '$perdidasFetales'),
        if (eclampsia != null) ('Eclampsia', eclampsia!),
        if (menopausia != null) ('Menopausia', menopausia!),
        if (metodoAnticonceptivo != null) ('Anticoncepción', metodoAnticonceptivo!),
      ];

  Map<String, dynamic> aJson() => {
        if (menarquia != null) 'menarquia': menarquia,
        if (ultimaMenstruacion != null) 'ultimaMenstruacion': ultimaMenstruacion,
        if (gestas != null) 'gestas': gestas,
        if (partos != null) 'partos': partos,
        if (cesareas != null) 'cesareas': cesareas,
        if (abortos != null) 'abortos': abortos,
        if (perdidasFetales != null) 'perdidasFetales': perdidasFetales,
        if (eclampsia != null) 'eclampsia': eclampsia,
        if (menopausia != null) 'menopausia': menopausia,
        if (trastornosMenstruales != null) 'trastornosMenstruales': trastornosMenstruales,
        if (metodoAnticonceptivo != null) 'metodoAnticonceptivo': metodoAnticonceptivo,
      };

  @override
  List<Object?> get props => [aJson()];
}

/// Antecedentes de la historia clínica: identificación y secciones III a V del modelo integral.
class Antecedentes extends Equatable {
  const Antecedentes({
    this.numeroHistoria,
    this.grupoSanguineo,
    this.datosSociales = const {},
    this.personales = const {},
    this.familiares = const {},
    this.habitos = const {},
    this.medicamentosActuales = const [],
    this.ginecoObstetricos,
    this.actualizadoEn,
    this.actualizadoPorMedico = false,
  });

  final String? numeroHistoria;
  final String? grupoSanguineo;

  /// Identificación del encabezado (lugar de nacimiento, religión, contacto de emergencia…).
  final Map<String, String> datosSociales;

  /// III. Antecedentes personales por clave del catálogo (inmunizaciones, infancia, alergicos…).
  final Map<String, List<String>> personales;

  /// IV. Antecedentes familiares por tipo (alergicos, metabolicos, neoplasias…).
  final Map<String, List<String>> familiares;

  /// V. Historia personal y social.
  final Map<String, String> habitos;
  final List<String> medicamentosActuales;
  final GinecoObstetricos? ginecoObstetricos;
  final DateTime? actualizadoEn;
  final bool actualizadoPorMedico;

  List<String> get alergicos => personales['alergicos'] ?? const [];
  List<String> lista(String clave) => personales[clave] ?? const [];

  bool get vacio =>
      grupoSanguineo == null &&
      datosSociales.isEmpty &&
      personales.values.every((l) => l.isEmpty) &&
      familiares.values.every((l) => l.isEmpty) &&
      habitos.isEmpty &&
      medicamentosActuales.isEmpty &&
      ginecoObstetricos == null;

  Map<String, dynamic> aJson() => {
        if (grupoSanguineo != null) 'grupoSanguineo': grupoSanguineo,
        'datosSociales': datosSociales,
        ...personales,
        'familiares': {
          for (final e in familiares.entries)
            if (e.value.isNotEmpty) e.key: e.value,
        },
        'habitos': habitos,
        'medicamentosActuales': medicamentosActuales,
        if (ginecoObstetricos != null) 'ginecoObstetricos': ginecoObstetricos!.aJson(),
      };

  @override
  List<Object?> get props => [aJson(), actualizadoEn];
}

class SignosVitales extends Equatable {
  const SignosVitales({
    this.tensionArterial,
    this.tensionArterialAcostado,
    this.tensionArterialDePie,
    this.frecuenciaCardiaca,
    this.frecuenciaRespiratoria,
    this.temperatura,
    this.saturacionOxigeno,
    this.peso,
    this.talla,
    this.circunferenciaAbdominal,
  });

  /// Presión arterial sentado (la de referencia).
  final String? tensionArterial;
  final String? tensionArterialAcostado;
  final String? tensionArterialDePie;
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

  bool get vacio => mediciones.isEmpty;

  static String n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Mediciones con dato: (etiqueta, valor, unidad), en el orden del modelo.
  List<(String, String, String)> get mediciones => [
        if (tensionArterialAcostado != null) ('PA acostado', tensionArterialAcostado!, 'mmHg'),
        if (tensionArterial != null) ('PA sentado', tensionArterial!, 'mmHg'),
        if (tensionArterialDePie != null) ('PA de pie', tensionArterialDePie!, 'mmHg'),
        if (frecuenciaCardiaca != null) ('Pulso', n(frecuenciaCardiaca!), 'ppm'),
        if (frecuenciaRespiratoria != null) ('Frec. respiratoria', n(frecuenciaRespiratoria!), 'rpm'),
        if (temperatura != null) ('Temperatura', n(temperatura!), '°C'),
        if (saturacionOxigeno != null) ('SpO₂', n(saturacionOxigeno!), '%'),
        if (peso != null) ('Peso', n(peso!), 'kg'),
        if (talla != null) ('Talla', n(talla!), 'cm'),
        if (imc != null) ('IMC', n(imc!), 'kg/m²'),
        if (circunferenciaAbdominal != null) ('C. abdominal', n(circunferenciaAbdominal!), 'cm'),
      ];

  Map<String, dynamic> aJson() => {
        if (tensionArterial != null) 'tensionArterial': tensionArterial,
        if (tensionArterialAcostado != null) 'tensionArterialAcostado': tensionArterialAcostado,
        if (tensionArterialDePie != null) 'tensionArterialDePie': tensionArterialDePie,
        if (frecuenciaCardiaca != null) 'frecuenciaCardiaca': frecuenciaCardiaca,
        if (frecuenciaRespiratoria != null) 'frecuenciaRespiratoria': frecuenciaRespiratoria,
        if (temperatura != null) 'temperatura': temperatura,
        if (saturacionOxigeno != null) 'saturacionOxigeno': saturacionOxigeno,
        if (peso != null) 'peso': peso,
        if (talla != null) 'talla': talla,
        if (circunferenciaAbdominal != null) 'circunferenciaAbdominal': circunferenciaAbdominal,
      };

  @override
  List<Object?> get props => [aJson()];
}

/// Historia de una consulta: secciones I, II y VI a XII del modelo integral.
class ContenidoConsulta extends Equatable {
  const ContenidoConsulta({
    required this.motivoConsulta,
    this.estimuloIatrotropico,
    required this.enfermedadActual,
    this.revisionSistemas = const {},
    this.revisionPorSistemas,
    this.condicionesGenerales,
    this.signosVitales = const SignosVitales(),
    this.examenRegiones = const {},
    this.examenFisico = '',
    this.resumenDatosPositivos,
    this.listaProblemas = const [],
    this.consentimientoInformado = false,
    required this.impresionDiagnostica,
    this.examenes = const {},
    this.planDiagnostico,
    this.planPreventivo,
    this.plan = '',
    this.indicaciones,
  });

  final String motivoConsulta;
  final String? estimuloIatrotropico;
  final String enfermedadActual;

  /// VI. Hallazgos por sistema (clave del catálogo → texto).
  final Map<String, String> revisionSistemas;

  /// VI. Observaciones generales (historias anteriores las guardaban aquí).
  final String? revisionPorSistemas;
  final String? condicionesGenerales;
  final SignosVitales signosVitales;

  /// VII. Hallazgos por región (clave del catálogo → texto).
  final Map<String, String> examenRegiones;
  final String examenFisico;
  final String? resumenDatosPositivos;
  final List<String> listaProblemas;
  final bool consentimientoInformado;
  final List<String> impresionDiagnostica;

  /// XI. Exámenes por tipo (laboratorio, imagenologicos, morfologicos, otros).
  final Map<String, String> examenes;
  final String? planDiagnostico;
  final String? planPreventivo;

  /// XII. Plan terapéutico.
  final String plan;

  /// XII. Plan educativo.
  final String? indicaciones;

  Map<String, dynamic> aJson() {
    bool lleno(String? v) => v != null && v.trim().isNotEmpty;
    Map<String, String> limpio(Map<String, String> m) => {
          for (final e in m.entries)
            if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
        };
    return {
      'motivoConsulta': motivoConsulta,
      if (lleno(estimuloIatrotropico)) 'estimuloIatrotropico': estimuloIatrotropico,
      'enfermedadActual': enfermedadActual,
      'revisionSistemas': limpio(revisionSistemas),
      if (lleno(revisionPorSistemas)) 'revisionPorSistemas': revisionPorSistemas,
      if (lleno(condicionesGenerales)) 'condicionesGenerales': condicionesGenerales,
      'signosVitales': signosVitales.aJson(),
      'examenRegiones': limpio(examenRegiones),
      'examenFisico': examenFisico,
      if (lleno(resumenDatosPositivos)) 'resumenDatosPositivos': resumenDatosPositivos,
      'listaProblemas': listaProblemas,
      'consentimientoInformado': consentimientoInformado,
      'impresionDiagnostica': impresionDiagnostica,
      'examenes': limpio(examenes),
      if (lleno(planDiagnostico)) 'planDiagnostico': planDiagnostico,
      if (lleno(planPreventivo)) 'planPreventivo': planPreventivo,
      'plan': plan,
      if (lleno(indicaciones)) 'indicaciones': indicaciones,
    };
  }

  @override
  List<Object?> get props => [aJson()];
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
    this.creadaEn,
  });

  final String id;
  final DateTime fecha;
  final ContenidoConsulta contenido;
  final bool editable;
  final String? citaId;
  final MedicoResumen? medico;
  final DateTime? creadaEn;

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
    this.nombres,
    this.apellidos,
    this.fechaNacimiento,
    this.cedula,
  });

  final String pacienteId;
  final String pacienteNombre;
  final String? nombres;
  final String? apellidos;
  final DateTime? fechaNacimiento;
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
  String get sexoLegible => switch (sexo) { 'F' => 'Femenino', 'M' => 'Masculino', _ => 'Otro' };
}
