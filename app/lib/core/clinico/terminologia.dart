/// Terminología médica estandarizada (HU Sprint 4): códigos CIE-10, unidades de dosis,
/// frecuencias y vías de administración, nota SOAP y rangos de referencia de laboratorio.
library;

/// Un diagnóstico de la Clasificación Internacional de Enfermedades, 10.ª revisión.
class CodigoCie10 {
  const CodigoCie10(this.codigo, this.descripcion);
  final String codigo;
  final String descripcion;

  /// Texto que se guarda en la historia: "J06.9 Infección aguda de las vías respiratorias superiores".
  String get etiqueta => '$codigo $descripcion';
}

/// Diagnósticos frecuentes en consulta ambulatoria (CIE-10, OPS/OMS).
const catalogoCie10 = <CodigoCie10>[
  CodigoCie10('A09', 'Diarrea y gastroenteritis de presunto origen infeccioso'),
  CodigoCie10('A90', 'Fiebre del dengue'),
  CodigoCie10('B01.9', 'Varicela sin complicaciones'),
  CodigoCie10('B34.9', 'Infección viral, no especificada'),
  CodigoCie10('B35.1', 'Tiña de las uñas'),
  CodigoCie10('B37.3', 'Candidiasis de la vulva y de la vagina'),
  CodigoCie10('B82.9', 'Parasitosis intestinal, sin otra especificación'),
  CodigoCie10('D50.9', 'Anemia por deficiencia de hierro, sin otra especificación'),
  CodigoCie10('D64.9', 'Anemia de tipo no especificado'),
  CodigoCie10('E03.9', 'Hipotiroidismo, no especificado'),
  CodigoCie10('E05.9', 'Tirotoxicosis, hipertiroidismo no especificado'),
  CodigoCie10('E10.9', 'Diabetes mellitus tipo 1, sin complicaciones'),
  CodigoCie10('E11.9', 'Diabetes mellitus tipo 2, sin complicaciones'),
  CodigoCie10('E11.6', 'Diabetes mellitus tipo 2 con otras complicaciones especificadas'),
  CodigoCie10('E28.2', 'Síndrome de ovario poliquístico'),
  CodigoCie10('E55.9', 'Deficiencia de vitamina D, no especificada'),
  CodigoCie10('E66.9', 'Obesidad, no especificada'),
  CodigoCie10('E78.0', 'Hipercolesterolemia pura'),
  CodigoCie10('E78.1', 'Hipergliceridemia pura'),
  CodigoCie10('E78.5', 'Hiperlipidemia, no especificada'),
  CodigoCie10('E86', 'Depleción del volumen (deshidratación)'),
  CodigoCie10('F32.9', 'Episodio depresivo, no especificado'),
  CodigoCie10('F41.1', 'Trastorno de ansiedad generalizada'),
  CodigoCie10('F41.9', 'Trastorno de ansiedad, no especificado'),
  CodigoCie10('F51.0', 'Insomnio no orgánico'),
  CodigoCie10('G43.9', 'Migraña, no especificada'),
  CodigoCie10('G44.2', 'Cefalea debida a tensión'),
  CodigoCie10('G47.3', 'Apnea del sueño'),
  CodigoCie10('G56.0', 'Síndrome del túnel carpiano'),
  CodigoCie10('H10.9', 'Conjuntivitis, no especificada'),
  CodigoCie10('H52.1', 'Miopía'),
  CodigoCie10('H66.9', 'Otitis media, no especificada'),
  CodigoCie10('I10', 'Hipertensión esencial (primaria)'),
  CodigoCie10('I20.9', 'Angina de pecho, no especificada'),
  CodigoCie10('I25.1', 'Enfermedad aterosclerótica del corazón'),
  CodigoCie10('I48', 'Fibrilación y aleteo auricular'),
  CodigoCie10('I50.9', 'Insuficiencia cardíaca, no especificada'),
  CodigoCie10('I63.9', 'Infarto cerebral, no especificado'),
  CodigoCie10('I83.9', 'Venas varicosas de los miembros inferiores sin úlcera ni inflamación'),
  CodigoCie10('I84.9', 'Hemorroides no especificadas, sin complicación'),
  CodigoCie10('J00', 'Rinofaringitis aguda (resfriado común)'),
  CodigoCie10('J01.9', 'Sinusitis aguda, no especificada'),
  CodigoCie10('J02.9', 'Faringitis aguda, no especificada'),
  CodigoCie10('J03.9', 'Amigdalitis aguda, no especificada'),
  CodigoCie10('J06.9', 'Infección aguda de las vías respiratorias superiores, no especificada'),
  CodigoCie10('J11.1', 'Influenza con otras manifestaciones respiratorias, virus no identificado'),
  CodigoCie10('J18.9', 'Neumonía, no especificada'),
  CodigoCie10('J20.9', 'Bronquitis aguda, no especificada'),
  CodigoCie10('J30.4', 'Rinitis alérgica, no especificada'),
  CodigoCie10('J32.9', 'Sinusitis crónica, no especificada'),
  CodigoCie10('J44.9', 'Enfermedad pulmonar obstructiva crónica, no especificada'),
  CodigoCie10('J45.9', 'Asma, no especificada'),
  CodigoCie10('K02.9', 'Caries dental, no especificada'),
  CodigoCie10('K21.9', 'Enfermedad del reflujo gastroesofágico sin esofagitis'),
  CodigoCie10('K25.9', 'Úlcera gástrica, no especificada'),
  CodigoCie10('K29.7', 'Gastritis, no especificada'),
  CodigoCie10('K30', 'Dispepsia'),
  CodigoCie10('K35.8', 'Apendicitis aguda, otra y la no especificada'),
  CodigoCie10('K40.9', 'Hernia inguinal unilateral, sin obstrucción ni gangrena'),
  CodigoCie10('K58.9', 'Síndrome del colon irritable sin diarrea'),
  CodigoCie10('K59.0', 'Estreñimiento'),
  CodigoCie10('K76.0', 'Degeneración grasa del hígado (hígado graso)'),
  CodigoCie10('K80.2', 'Cálculo de la vesícula biliar sin colecistitis'),
  CodigoCie10('L20.9', 'Dermatitis atópica, no especificada'),
  CodigoCie10('L23.9', 'Dermatitis alérgica de contacto, de causa no especificada'),
  CodigoCie10('L30.9', 'Dermatitis, no especificada'),
  CodigoCie10('L40.0', 'Psoriasis vulgar'),
  CodigoCie10('L50.9', 'Urticaria, no especificada'),
  CodigoCie10('L70.0', 'Acné vulgar'),
  CodigoCie10('M06.9', 'Artritis reumatoide, no especificada'),
  CodigoCie10('M10.9', 'Gota, no especificada'),
  CodigoCie10('M17.9', 'Gonartrosis, no especificada'),
  CodigoCie10('M19.9', 'Artrosis, no especificada'),
  CodigoCie10('M25.5', 'Dolor en articulación'),
  CodigoCie10('M54.2', 'Cervicalgia'),
  CodigoCie10('M54.5', 'Lumbago no especificado'),
  CodigoCie10('M75.1', 'Síndrome del manguito rotador'),
  CodigoCie10('M79.1', 'Mialgia'),
  CodigoCie10('M81.9', 'Osteoporosis, no especificada'),
  CodigoCie10('N18.9', 'Enfermedad renal crónica, no especificada'),
  CodigoCie10('N20.0', 'Cálculo del riñón'),
  CodigoCie10('N39.0', 'Infección de vías urinarias, sitio no especificado'),
  CodigoCie10('N40', 'Hiperplasia de la próstata'),
  CodigoCie10('N76.0', 'Vaginitis aguda'),
  CodigoCie10('N94.6', 'Dismenorrea, no especificada'),
  CodigoCie10('N95.1', 'Estados menopáusicos y climatéricos femeninos'),
  CodigoCie10('O80', 'Parto único espontáneo'),
  CodigoCie10('R05', 'Tos'),
  CodigoCie10('R10.4', 'Otros dolores abdominales y los no especificados'),
  CodigoCie10('R11', 'Náusea y vómito'),
  CodigoCie10('R42', 'Mareo y desvanecimiento'),
  CodigoCie10('R50.9', 'Fiebre, no especificada'),
  CodigoCie10('R51', 'Cefalea'),
  CodigoCie10('R53', 'Malestar y fatiga'),
  CodigoCie10('S93.4', 'Esguince y torcedura del tobillo'),
  CodigoCie10('T78.4', 'Alergia no especificada'),
  CodigoCie10('Z00.0', 'Examen médico general'),
  CodigoCie10('Z00.1', 'Control de salud de rutina del niño'),
  CodigoCie10('Z01.4', 'Examen ginecológico (general) (de rutina)'),
  CodigoCie10('Z34.9', 'Supervisión de embarazo normal, no especificado'),
  CodigoCie10('Z71.3', 'Consulta para instrucción y vigilancia de la dieta'),
];

/// Código CIE-10 al inicio del texto: una letra, dos dígitos y, opcionalmente, un punto y más caracteres.
final _codigoCie10 = RegExp(r'^[A-Z][0-9][0-9A-Z](\.[0-9A-Z]{1,4})?(\s|$)');

/// El diagnóstico empieza con un código CIE-10 (p. ej. "I10 Hipertensión esencial").
bool tieneCodigoCie10(String diagnostico) => _codigoCie10.hasMatch(diagnostico.trim());

/// Busca por código o por palabras de la descripción, sin importar mayúsculas ni tildes.
List<CodigoCie10> buscarCie10(String consulta, {int limite = 12}) {
  final q = _normalizar(consulta);
  if (q.isEmpty) return const [];
  final palabras = q.split(RegExp(r'\s+'));
  return catalogoCie10
      .where((c) {
        final texto = _normalizar('${c.codigo} ${c.descripcion}');
        return palabras.every(texto.contains);
      })
      .take(limite)
      .toList();
}

String _normalizar(String s) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  var r = s.toLowerCase().trim();
  for (var i = 0; i < con.length; i++) {
    r = r.replaceAll(con[i], sin[i]);
  }
  return r;
}

// ---------- Récipes ----------

/// Unidades válidas para la dosis: Sistema Internacional, UI y mEq, más las formas farmacéuticas que se cuentan.
const unidadesDosis = ['mg', 'g', 'mcg', 'ml', 'UI', 'mEq', 'tableta(s)', 'cápsula(s)', 'gota(s)', 'ampolla(s)', 'sobre(s)', 'puff', 'aplicación(es)'];

/// Frecuencias estandarizadas (las entiende también el planificador de recordatorios).
const frecuenciasEstandar = [
  'cada 4 horas',
  'cada 6 horas',
  'cada 8 horas',
  'cada 12 horas',
  'cada 24 horas',
  'una vez a la semana',
  'dosis única',
  'si hay dolor o fiebre',
];

const viasAdministracion = [
  'Vía oral',
  'Vía sublingual',
  'Vía tópica',
  'Vía oftálmica',
  'Vía ótica',
  'Vía nasal',
  'Vía inhalatoria',
  'Vía intramuscular',
  'Vía intravenosa',
  'Vía subcutánea',
  'Vía rectal',
  'Vía vaginal',
];

final _dosis = RegExp(
  r'^\d+([.,]\d+)?\s*(mg|g|mcg|µg|ml|UI|mEq|tabletas?|tableta\(s\)|c[aá]psulas?|c[aá]psula\(s\)|gotas?|gota\(s\)|ampollas?|ampolla\(s\)|sobres?|sobre\(s\)|puffs?|aplicaci[oó]n(es)?|aplicación\(es\))$',
  caseSensitive: false,
);

/// La dosis tiene una cantidad y una unidad reconocida ("500 mg", "1 tableta", "10 ml").
bool dosisValida(String dosis) => _dosis.hasMatch(dosis.trim());

/// Arma la dosis a partir de la cantidad y la unidad elegida en el formulario.
String componerDosis(String cantidad, String unidad) {
  final n = cantidad.trim().replaceAll(',', '.');
  final uno = double.tryParse(n) == 1;
  if (unidad == 'aplicación(es)') return '$n ${uno ? 'aplicación' : 'aplicaciones'}';
  final u = unidad.replaceAllMapped(RegExp(r'\((s|es)\)$'), (m) => uno ? '' : m[1]!);
  return '$n $u';
}

// ---------- Nota de evolución SOAP ----------

/// Nota de evolución con la estructura SOAP: Subjetivo, Objetivo, Análisis y Plan.
String componerNotaSoap({required String subjetivo, required String objetivo, required String analisis, required String plan}) =>
    [
      'S (Subjetivo): ${subjetivo.trim()}',
      'O (Objetivo): ${objetivo.trim()}',
      'A (Análisis): ${analisis.trim()}',
      'P (Plan): ${plan.trim()}',
    ].join('\n');

// ---------- Laboratorio ----------

/// Posición del valor respecto al rango de referencia: -1 bajo, 0 dentro, 1 alto, null si no se puede comparar.
int? posicionEnRango(String valor, String? rango) {
  final v = double.tryParse(valor.trim().replaceAll(',', '.'));
  if (v == null || rango == null || rango.trim().isEmpty) return null;
  final r = rango.replaceAll(',', '.').replaceAll('–', '-').replaceAll('—', '-');
  final numero = RegExp(r'\d+(\.\d+)?');
  final intervalo = RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)').firstMatch(r);
  if (intervalo != null) {
    final min = double.parse(intervalo[1]!), max = double.parse(intervalo[2]!);
    return v < min ? -1 : (v > max ? 1 : 0);
  }
  final limite = numero.firstMatch(r);
  if (limite == null) return null;
  final x = double.parse(limite[0]!);
  final incluye = r.contains('=') || r.contains('≤') || r.contains('≥');
  if (r.contains('<') || r.contains('≤')) return v < x || (incluye && v == x) ? 0 : 1;
  if (r.contains('>') || r.contains('≥')) return v > x || (incluye && v == x) ? 0 : -1;
  return null;
}
