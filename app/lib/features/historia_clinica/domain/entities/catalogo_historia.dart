/// Catálogo del modelo de historia clínica integral (secciones I a XII): claves
/// que entiende la API, etiquetas, guías de interrogatorio y sugerencias rápidas.
library;

class CampoHistoria {
  const CampoHistoria(this.clave, this.etiqueta, {this.guia, this.sugerencias = const []});
  final String clave;
  final String etiqueta;

  /// Qué interrogar o explorar en este campo, tal como lo lista el modelo.
  final String? guia;

  /// Opciones del modelo que se agregan con un toque.
  final List<String> sugerencias;
}

/// Encabezado: identificación que no está en el perfil del paciente.
const camposIdentificacion = <CampoHistoria>[
  CampoHistoria('lugarNacimiento', 'Lugar de nacimiento'),
  CampoHistoria('procedencia', 'Lugar de procedencia'),
  CampoHistoria('nacionalidad', 'Nacionalidad'),
  CampoHistoria('estadoCivil', 'Estado civil'),
  CampoHistoria('nivelInstruccion', 'Nivel de instrucción'),
  CampoHistoria('ocupacion', 'Profesión u ocupación'),
  CampoHistoria('religion', 'Religión'),
  CampoHistoria('direccion', 'Dirección y teléfono'),
  CampoHistoria('seguridadSocial', 'Seguridad social'),
  CampoHistoria('contactoEmergencia', 'En emergencia avisar a'),
  CampoHistoria('telefonoEmergencia', 'Teléfono de emergencia'),
];

/// III. Antecedentes personales, numerados como el modelo (el 10 son los ginecobstétricos).
const antecedentesPersonales = <(int, CampoHistoria)>[
  (1, CampoHistoria('inmunizaciones', 'Inmunizaciones', sugerencias: ['BCG', 'Polio', 'Pentavalente', 'Triple viral (SRP)', 'Hepatitis B', 'Influenza', 'Td', 'COVID-19', 'Fiebre amarilla'])),
  (2, CampoHistoria('infancia', 'Enfermedades de la infancia', sugerencias: ['Sarampión', 'Rubéola', 'Tos ferina', 'Difteria', 'Parotiditis', 'Varicela', 'Otitis', 'Faringitis', 'Faringoamigdalitis', 'Rinofaringitis', 'Gastroenteritis', 'Influenza', 'Catarros', 'Bronquitis', 'Asma bronquial', 'Artropatías', 'Parasitosis'])),
  (3, CampoHistoria('alergicos', 'Alergias', guia: 'Medicamentos, alimentos u otras, con la reacción', sugerencias: ['Erupciones', 'Rinitis', 'Medicamentos', 'Asma bronquial'])),
  (4, CampoHistoria('parasitosis', 'Parasitosis', sugerencias: ['Bilharziosis', 'Chagas', 'Paludismo', 'Leishmaniasis', 'Toxoplasmosis', 'Necatoriasis', 'Amibiasis'])),
  (5, CampoHistoria('infecciones', 'Infecciones', sugerencias: ['Hansen', 'TBC', 'Mononucleosis', 'Hepatitis', 'Tifoidea', 'Citomegalovirus', 'Otitis', 'Neumonía', 'Diarreas', 'Meningitis', 'Sinusitis', 'ITU'])),
  (6, CampoHistoria('transmisionSexual', 'Enfermedades de transmisión sexual', sugerencias: ['Sífilis', 'Blenorragia', 'Virus del papiloma', 'Chancro blando', 'VIH'])),
  (7, CampoHistoria('epidemiologicos', 'Epidemiológicos', sugerencias: ['Sitios visitados', 'Viajes', 'Contacto personal', 'Contacto animal'])),
  (8, CampoHistoria('patologicos', 'Médicos', sugerencias: ['HTA', 'Cardiopatía isquémica', 'Úlcera gastroduodenal', 'Dislipidemia', 'Diabetes mellitus', 'Enfermedad respiratoria', 'Bronquitis', 'Neumonía', 'Glomerulonefritis', 'Nefrosis', 'Litiasis renal', 'Pielonefritis', 'Enfermedad renal', 'Enfermedad endocrinológica'])),
  (9, CampoHistoria('quirurgicos', 'Quirúrgicos', guia: 'Fecha, sitio, indicación, complicaciones y hallazgos')),
  (11, CampoHistoria('traumatologicos', 'Traumatológicos')),
  (12, CampoHistoria('psiquiatricos', 'Psiquiátricos')),
  (13, CampoHistoria('laborales', 'Laborales')),
  (14, CampoHistoria('intoxicaciones', 'Intoxicaciones')),
  (15, CampoHistoria('radiaciones', 'Radiaciones')),
  (16, CampoHistoria('transfusionales', 'Transfusionales')),
];

/// IV. Antecedentes familiares por tipo.
const antecedentesFamiliares = <CampoHistoria>[
  CampoHistoria('alergicos', 'Alérgicos'),
  CampoHistoria('infecciosos', 'Infecciosos', sugerencias: ['TBC', 'Hepatitis', 'Mononucleosis', 'Citomegalovirus']),
  CampoHistoria('metabolicos', 'Metabólicos', sugerencias: ['Dislipidemia', 'Diabetes', 'Gota', 'Obesidad', 'Enfermedad tiroidea']),
  CampoHistoria('neoplasias', 'Neoplasias', sugerencias: ['Cáncer mamario', 'Cáncer gástrico', 'Cáncer de colon', 'Linfomas']),
  CampoHistoria('cardiovasculares', 'Cardiovasculares', sugerencias: ['Enfermedad coronaria', 'HTA', 'ACV']),
  CampoHistoria('mentales', 'Mentales', sugerencias: ['Depresión', 'Psicosis', 'Neurosis']),
  CampoHistoria('hematologicos', 'Hematológicos', sugerencias: ['Anemia', 'Diátesis hemorrágica', 'Leucemias']),
  CampoHistoria('inmunologicos', 'Inmunológicos', sugerencias: ['Artritis reumatoide', 'Lupus eritematoso', 'Púrpura']),
  CampoHistoria('articulares', 'Articulares', sugerencias: ['Osteoartritis']),
  CampoHistoria('otros', 'Otros'),
];

/// V. Historia personal y social.
const habitosCatalogo = <CampoHistoria>[
  CampoHistoria('alcohol', 'Alcohol'),
  CampoHistoria('tabaco', 'Tabaco'),
  CampoHistoria('cafe', 'Café'),
  CampoHistoria('drogas', 'Drogas ilícitas'),
  CampoHistoria('drogasLicitas', 'Drogas lícitas'),
  CampoHistoria('sexuales', 'Sexuales'),
  CampoHistoria('actividadFisica', 'Ejercicio'),
  CampoHistoria('sueno', 'Sueño'),
  CampoHistoria('alimentacion', 'Nutrición'),
  CampoHistoria('otraActividad', 'Otra actividad'),
  CampoHistoria('vivienda', 'Vivienda'),
  CampoHistoria('otros', 'Otros'),
];

/// VI. Revisión por aparatos y sistemas.
const sistemasRevision = <CampoHistoria>[
  CampoHistoria('general', 'General', guia: 'Cambios de peso, fiebre, astenia, mareos, debilidad'),
  CampoHistoria('piel', 'Piel', guia: 'Prurito, erupciones, máculas, úlceras, petequias, color, hirsutismo, acné, diaforesis'),
  CampoHistoria('cabeza', 'Cabeza', guia: 'Cefalea, mareos, vértigo'),
  CampoHistoria('ojos', 'Ojos', guia: 'Visión, lentes, dolor, fotofobia, epífora, secreciones, diplopía, visión borrosa'),
  CampoHistoria('oidos', 'Oídos', guia: 'Audición, dolor, tinnitus, hipoacusia, secreciones'),
  CampoHistoria('nariz', 'Nariz y senos paranasales', guia: 'Anosmia, secreción, epistaxis, rinorrea anterior o posterior'),
  CampoHistoria('bocaFaringe', 'Boca y faringe', guia: 'Úlceras, caries, dolor, xerostomía, gingivorragia, halitosis, disfonía, disfagia'),
  CampoHistoria('cuello', 'Cuello', guia: 'Dolor, aumento de volumen, masas, rigidez'),
  CampoHistoria('mamas', 'Mamas', guia: 'Secreciones, ginecomastia, nódulos, cambios de tamaño'),
  CampoHistoria('cardiovascular', 'Cardiovascular', guia: 'Dolor, disnea, palpitaciones, edema, cianosis, claudicación'),
  CampoHistoria('respiratorio', 'Respiratorio', guia: 'Disnea, tos, expectoración, dolor, hemoptisis, sibilancias'),
  CampoHistoria('digestivo', 'Digestivo', guia: 'Dolor abdominal, apetito, constipación, diarrea, náuseas, vómitos, pirosis, melena, ictericia'),
  CampoHistoria('urinario', 'Urinario', guia: 'Dolor lumbar, disuria, polaquiuria, nicturia, hematuria, incontinencia'),
  CampoHistoria('ginecologico', 'Ginecológico', guia: 'Menstruaciones, amenorrea, metrorragia, flujo, dispareunia, dismenorrea, FUM'),
  CampoHistoria('osteoarticular', 'Osteoarticular', guia: 'Dolor, deformidad, aumento de volumen, limitación funcional, mialgias'),
  CampoHistoria('neurologico', 'Neurológico', guia: 'Lipotimia, síncope, convulsiones, temblores, paresias, parestesias, marcha'),
  CampoHistoria('endocrino', 'Endocrinológico', guia: 'Galactorrea, astenia, hirsutismo, intolerancia al frío, libido'),
  CampoHistoria('inmunologico', 'Inmunológico', guia: 'Prurito, habones'),
  CampoHistoria('hematologico', 'Hematológico', guia: 'Petequias, equimosis, gingivorragia, adenomegalias'),
  CampoHistoria('psiquiatrico', 'Psiquiátrico'),
];

/// VII. Examen físico por regiones.
const regionesExamen = <CampoHistoria>[
  CampoHistoria('piel', 'Piel', guia: 'Color, humedad, temperatura, elasticidad, lesiones, faneras, uñas'),
  CampoHistoria('cabeza', 'Cabeza', guia: 'Configuración, dolor, cabellos'),
  CampoHistoria('ojos', 'Ojos', guia: 'Párpados, conjuntivas, escleróticas, pupilas, movimientos oculares, fondo de ojo'),
  CampoHistoria('oidos', 'Oídos', guia: 'Pabellones, conductos auditivos, tímpanos, mastoides, audición'),
  CampoHistoria('nariz', 'Nariz', guia: 'Tabique, mucosas, cornetes, secreción, senos paranasales'),
  CampoHistoria('bocaFaringe', 'Boca y faringe', guia: 'Labios, lengua, dentadura, encías, amígdalas, úvula, laringe'),
  CampoHistoria('cuello', 'Cuello', guia: 'Movimientos, vasos, tiroides, ganglios, pulsos carotídeos'),
  CampoHistoria('torax', 'Tórax', guia: 'Aspecto, expansibilidad, simetría, deformidad'),
  CampoHistoria('respiratorio', 'Respiratorio', guia: 'Frémito vocal, percusión, ruidos pulmonares'),
  CampoHistoria('cardiovascular', 'Cardiovascular', guia: 'Pulsos, ápex, frémitos, ruidos cardíacos, soplos, frotes'),
  CampoHistoria('mamas', 'Mamas', guia: 'Aspecto, retracciones, nódulos, secreciones'),
  CampoHistoria('abdomen', 'Abdomen', guia: 'Aspecto, cicatrices, peristalsis, visceromegalias, masas, ascitis, puntos dolorosos, hernias'),
  CampoHistoria('lumbar', 'Lumbar', guia: 'Percusión lumbar'),
  CampoHistoria('rectal', 'Rectal', guia: 'Hemorroides, fisuras, esfínter, ampolla, próstata'),
  CampoHistoria('ginecologico', 'Ginecológico', guia: 'Genitales externos, vagina y cuello, útero, anexos'),
  CampoHistoria('genitalesMasculinos', 'Genitales masculinos'),
  CampoHistoria('extremidades', 'Extremidades', guia: 'Pulsos, edema, várices, pies, úlceras'),
  CampoHistoria('osteomuscular', 'Huesos, articulaciones y músculos', guia: 'Deformidad, dolor, movilidad, nódulos, atrofia, sinovitis'),
  CampoHistoria('columna', 'Columna (eje axial)', guia: 'Xifosis, escoliosis, dolor, movilidad'),
  CampoHistoria('neurologico', 'Neurológico', guia: 'Conciencia, pares craneales, marcha, coordinación, fuerza, tono, reflejos, sensibilidad'),
  CampoHistoria('mental', 'Mental', guia: 'Orientación, conducta, memoria, pensamiento'),
  CampoHistoria('ganglios', 'Ganglios linfáticos', guia: 'Cervicales, supraclaviculares, axilares, inguinales, poplíteos'),
];

/// XI. Exámenes.
const tiposExamenes = <CampoHistoria>[
  CampoHistoria('laboratorio', 'Laboratorio'),
  CampoHistoria('imagenologicos', 'Imagenológicos'),
  CampoHistoria('morfologicos', 'Morfológicos'),
  CampoHistoria('otros', 'Otros'),
];
