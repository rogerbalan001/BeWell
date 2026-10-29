import { LineaPdf } from '../../../shared/application/generador-pdf';
import { Medico } from '../../medicos/domain/medico';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { AntecedentesClinicos } from '../domain/antecedentes-clinicos';
import {
  CLAVES_HABITOS,
  CLAVES_IDENTIFICACION,
  LISTAS_PERSONALES,
  REGIONES_EXAMEN,
  SISTEMAS_REVISION,
  TIPOS_EXAMENES,
  TIPOS_FAMILIARES,
} from '../domain/catalogo-historia';
import { ConsultaClinica } from '../domain/consulta-clinica';

/** Etiquetas del modelo de historia clínica integral, en el orden en que se imprimen. */
export const ETIQUETAS = {
  identificacion: {
    lugarNacimiento: 'Lugar de nacimiento',
    procedencia: 'Lugar de procedencia',
    nacionalidad: 'Nacionalidad',
    estadoCivil: 'Estado civil',
    nivelInstruccion: 'Nivel de instrucción',
    ocupacion: 'Profesión u ocupación',
    religion: 'Religión',
    direccion: 'Dirección y teléfono',
    seguridadSocial: 'Seguridad social',
    contactoEmergencia: 'En caso de emergencia avisar a',
    telefonoEmergencia: 'Teléfono de emergencia',
  },
  personales: {
    inmunizaciones: 'Inmunizaciones',
    infancia: 'Enfermedades de la infancia',
    alergicos: 'Alergias',
    parasitosis: 'Parasitosis',
    infecciones: 'Infecciones',
    transmisionSexual: 'Enfermedades de transmisión sexual',
    epidemiologicos: 'Epidemiológicos',
    patologicos: 'Médicos',
    quirurgicos: 'Quirúrgicos',
    traumatologicos: 'Traumatológicos',
    psiquiatricos: 'Psiquiátricos',
    laborales: 'Laborales',
    intoxicaciones: 'Intoxicaciones',
    radiaciones: 'Radiaciones',
    transfusionales: 'Transfusionales',
  },
  familiares: {
    alergicos: 'Alérgicos',
    infecciosos: 'Infecciosos',
    metabolicos: 'Metabólicos',
    neoplasias: 'Neoplasias',
    cardiovasculares: 'Cardiovasculares',
    mentales: 'Mentales',
    hematologicos: 'Hematológicos',
    inmunologicos: 'Inmunológicos',
    articulares: 'Articulares',
    otros: 'Otros',
  },
  habitos: {
    alcohol: 'Alcohol',
    tabaco: 'Tabaco',
    cafe: 'Café',
    drogas: 'Drogas ilícitas',
    drogasLicitas: 'Drogas lícitas',
    sexuales: 'Sexuales',
    actividadFisica: 'Ejercicio',
    sueno: 'Sueño',
    alimentacion: 'Nutrición',
    otraActividad: 'Otra actividad',
    vivienda: 'Vivienda',
    otros: 'Otros',
  },
  sistemas: {
    general: 'General',
    piel: 'Piel',
    cabeza: 'Cabeza',
    ojos: 'Ojos',
    oidos: 'Oídos',
    nariz: 'Nariz y senos paranasales',
    bocaFaringe: 'Boca y faringe',
    cuello: 'Cuello',
    mamas: 'Mamas',
    cardiovascular: 'Cardiovascular',
    respiratorio: 'Respiratorio',
    digestivo: 'Digestivo',
    urinario: 'Urinario',
    ginecologico: 'Ginecológico',
    osteoarticular: 'Osteoarticular',
    neurologico: 'Neurológico',
    endocrino: 'Endocrinológico',
    inmunologico: 'Inmunológico',
    hematologico: 'Hematológico',
    psiquiatrico: 'Psiquiátrico',
  },
  regiones: {
    piel: 'Piel',
    cabeza: 'Cabeza',
    ojos: 'Ojos',
    oidos: 'Oídos',
    nariz: 'Nariz',
    bocaFaringe: 'Boca y faringe',
    cuello: 'Cuello',
    torax: 'Tórax',
    respiratorio: 'Respiratorio',
    cardiovascular: 'Cardiovascular',
    mamas: 'Mamas',
    abdomen: 'Abdomen',
    lumbar: 'Lumbar',
    rectal: 'Rectal',
    ginecologico: 'Ginecológico',
    genitalesMasculinos: 'Genitales masculinos',
    extremidades: 'Extremidades',
    osteomuscular: 'Huesos, articulaciones y músculos',
    columna: 'Columna (eje axial)',
    neurologico: 'Neurológico',
    mental: 'Mental',
    ganglios: 'Ganglios linfáticos',
  },
  examenes: { laboratorio: 'Laboratorio', imagenologicos: 'Imagenológicos', morfologicos: 'Morfológicos', otros: 'Otros' },
} as const;

const fecha = (d: Date) => d.toISOString().slice(0, 10);
const seccion = (texto: string): LineaPdf => ({ texto, tamano: 12, negrita: true, color: 'primario', espacioAntes: 14 });
const subtitulo = (texto: string): LineaPdf => ({ texto, negrita: true, espacioAntes: 6 });
const dato = (etiqueta: string, valor?: string): LineaPdf[] => (valor ? [{ texto: `${etiqueta}: ${valor}` }] : []);

/** Arma las líneas del PDF de la historia clínica, sección por sección como el modelo integral. */
export function lineasHistoriaPdf(datos: {
  paciente: PerfilPaciente;
  antecedentes: AntecedentesClinicos | null;
  consultas: ConsultaClinica[];
  verConsultas: boolean;
  parcial?: string;
  medicos: Map<string, Medico>;
  ahora: Date;
}): LineaPdf[] {
  const { paciente, antecedentes, consultas, medicos, ahora } = datos;
  const a = antecedentes?.datos;
  const sexo = paciente.sexo === 'F' ? 'Femenino' : paciente.sexo === 'M' ? 'Masculino' : 'Otro';
  const lineas: LineaPdf[] = [
    { texto: 'Bewell - Historia clínica integral', tamano: 18, negrita: true, color: 'primario' },
    { texto: `N.º de historia ${antecedentes ? `HC-${antecedentes.id.slice(-6).toUpperCase()}` : '-'} · generada el ${fecha(ahora)}`, color: 'tenue' },
    ...(datos.parcial ? [{ texto: datos.parcial, color: 'tenue' as const }] : []),
    seccion('Identificación'),
    { texto: `Apellidos: ${paciente.apellidos} · Nombres: ${paciente.nombres} · Sexo: ${sexo}` },
    { texto: `Fecha de nacimiento: ${fecha(paciente.fechaNacimiento)} · Edad: ${paciente.edad(ahora)} años · C.I.: ${paciente.cedula ?? 'no registrada'}` },
    ...(a?.grupoSanguineo ? [{ texto: `Grupo sanguíneo: ${a.grupoSanguineo}` }] : []),
    ...(a ? CLAVES_IDENTIFICACION.flatMap((k) => dato(ETIQUETAS.identificacion[k], a.datosSociales[k])) : []),
  ];

  if (a) {
    const lista = (titulo: string, valores: string[] = []): LineaPdf[] => [
      { texto: `${titulo}: ${valores.length ? valores.join('; ') : 'niega'}`, color: valores.length ? 'normal' : 'tenue' },
    ];
    lineas.push(seccion('III. Antecedentes personales'));
    LISTAS_PERSONALES.forEach((k, i) => {
      lineas.push(...lista(`${i + 1}. ${ETIQUETAS.personales[k]}`, a[k]));
      if (k === 'quirurgicos' && a.ginecoObstetricos) {
        const g = a.ginecoObstetricos;
        const partes = [
          `G${g.gestas ?? 0} P${g.partos ?? 0} C${g.cesareas ?? 0} A${g.abortos ?? 0}`,
          g.perdidasFetales !== undefined && `pérdidas fetales ${g.perdidasFetales}`,
          g.menarquia && `menarquia ${g.menarquia}`,
          g.ultimaMenstruacion && `FUM ${g.ultimaMenstruacion}`,
          g.trastornosMenstruales && `trastornos menstruales: ${g.trastornosMenstruales}`,
          g.eclampsia && `eclampsia: ${g.eclampsia}`,
          g.menopausia && `menopausia: ${g.menopausia}`,
          g.metodoAnticonceptivo && `anticoncepción: ${g.metodoAnticonceptivo}`,
        ].filter(Boolean);
        lineas.push({ texto: `Ginecobstétricos: ${partes.join('; ')}` });
      }
    });
    lineas.push(seccion('IV. Antecedentes familiares'));
    TIPOS_FAMILIARES.forEach((k) => {
      if (k !== 'otros' || a.familiares.otros?.length) lineas.push(...lista(ETIQUETAS.familiares[k], a.familiares[k]));
    });
    lineas.push(seccion('V. Historia personal y social'));
    for (const k of CLAVES_HABITOS) lineas.push(...dato(ETIQUETAS.habitos[k], a.habitos[k]));
    lineas.push(...lista('Medicamentos', a.medicamentosActuales));
  }

  if (datos.verConsultas) {
    lineas.push(seccion(`Consultas (${consultas.length})`));
    for (const c of consultas) {
      const medico = medicos.get(c.medicoId);
      const sv = c.signosVitales;
      const signos = [
        sv.tensionArterialAcostado && `PA acostado ${sv.tensionArterialAcostado}`,
        sv.tensionArterial && `PA sentado ${sv.tensionArterial}`,
        sv.tensionArterialDePie && `PA de pie ${sv.tensionArterialDePie}`,
        sv.frecuenciaCardiaca && `pulso ${sv.frecuenciaCardiaca} ppm`,
        sv.frecuenciaRespiratoria && `FR ${sv.frecuenciaRespiratoria} rpm`,
        sv.temperatura && `T ${sv.temperatura} °C`,
        sv.saturacionOxigeno && `SpO2 ${sv.saturacionOxigeno} %`,
        sv.peso && `peso ${sv.peso} kg`,
        sv.talla && `talla ${sv.talla} cm`,
        c.imc && `IMC ${c.imc}`,
        sv.circunferenciaAbdominal && `C. abdominal ${sv.circunferenciaAbdominal} cm`,
      ].filter(Boolean);
      const sinRevision = SISTEMAS_REVISION.filter((k) => !c.revisionSistemas[k]).map((k) => ETIQUETAS.sistemas[k]);
      lineas.push({ texto: `${fecha(c.fecha)} · ${c.motivoConsulta}`, tamano: 11, negrita: true, espacioAntes: 14 });
      lineas.push(
        subtitulo('I. Motivo de consulta'),
        { texto: c.motivoConsulta },
        ...dato('Estímulo iatrotrópico', c.estimuloIatrotropico),
        subtitulo('II. Enfermedad actual'),
        { texto: c.enfermedadActual },
        subtitulo('VI. Revisión por aparatos y sistemas'),
        ...SISTEMAS_REVISION.flatMap((k) => dato(ETIQUETAS.sistemas[k], c.revisionSistemas[k])),
        ...dato('Observaciones', c.revisionPorSistemas),
        ...(sinRevision.length ? [{ texto: `Sin síntomas referidos: ${sinRevision.join(', ')}.`, color: 'tenue' as const }] : []),
        subtitulo('VII. Examen físico'),
        ...dato('Condiciones generales', c.condicionesGenerales),
        ...dato('Signos vitales', signos.join(' · ')),
        ...REGIONES_EXAMEN.flatMap((k) => dato(ETIQUETAS.regiones[k], c.examenRegiones[k])),
        ...dato('Observaciones', c.examenFisico),
        ...(c.resumenDatosPositivos ? [subtitulo('VIII. Resumen de datos positivos'), { texto: c.resumenDatosPositivos }] : []),
        subtitulo('IX. Lista de problemas'),
        { texto: c.listaProblemas.length ? c.listaProblemas.map((p, i) => `${i + 1}. ${p}`).join('  ') : 'Sin problemas registrados.' },
        { texto: `Consentimiento informado: ${c.consentimientoInformado ? 'sí' : 'no registrado'}`, color: 'tenue' },
        subtitulo('X. Impresión diagnóstica'),
        { texto: c.impresionDiagnostica.map((d, i) => `${i + 1}. ${d}`).join('  ') },
        subtitulo('XI. Exámenes'),
        ...TIPOS_EXAMENES.flatMap((k) => dato(ETIQUETAS.examenes[k], c.examenes[k])),
        subtitulo('XII. Plan'),
        ...dato('Diagnóstico', c.planDiagnostico),
        ...dato('Preventivo', c.planPreventivo),
        ...dato('Educativo', c.indicaciones),
        ...dato('Terapéutico', c.plan),
        {
          texto: `Elaborada por ${medico ? `${medico.nombreCompleto} (${medico.especialidades[0]})` : 'el médico tratante'} · ${fecha(c.creadaEn)}`,
          color: 'tenue',
          espacioAntes: 6,
        },
      );
    }
  }

  lineas.push({
    texto: 'Documento generado por Bewell. La información clínica es propiedad del paciente y su uso está sujeto a su consentimiento.',
    tamano: 8,
    color: 'tenue',
    espacioAntes: 20,
  });
  return lineas;
}
