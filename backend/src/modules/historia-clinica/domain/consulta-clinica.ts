import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { HORA_MS } from '../../../shared/domain/reloj';

/** Plazo en el que el médico autor puede corregir la historia de una consulta. */
export const HORAS_EDICION_CONSULTA = 24;

export interface SignosVitales {
  /** Formato "sistólica/diastólica", p. ej. "120/80" (mmHg). */
  tensionArterial?: string;
  /** Latidos por minuto. */
  frecuenciaCardiaca?: number;
  /** Respiraciones por minuto. */
  frecuenciaRespiratoria?: number;
  /** Grados Celsius. */
  temperatura?: number;
  /** Porcentaje (SpO2). */
  saturacionOxigeno?: number;
  /** Kilogramos. */
  peso?: number;
  /** Centímetros. */
  talla?: number;
  /** Circunferencia abdominal en centímetros. */
  circunferenciaAbdominal?: number;
}

/**
 * Contenido clínico de la consulta (se guarda cifrado a nivel de campo).
 * Resume las secciones I, II y VI a XII del modelo de historia clínica integral.
 */
export interface ContenidoConsulta {
  /** I. Motivo de consulta. */
  motivoConsulta: string;
  /** I. Estímulo iatrotrópico: por qué consulta ahora. */
  estimuloIatrotropico?: string;
  /** II. Enfermedad actual, en orden cronológico. */
  enfermedadActual: string;
  /** VI. Revisión por aparatos y sistemas. */
  revisionPorSistemas?: string;
  condicionesGenerales?: string;
  signosVitales: SignosVitales;
  /** VII. Examen físico. */
  examenFisico: string;
  /** IX. Lista de problemas. */
  listaProblemas: string[];
  /** X. Impresión diagnóstica. */
  impresionDiagnostica: string[];
  /** XI. Exámenes solicitados (laboratorio, imagen, otros). */
  examenes?: string;
  /** XII. Plan diagnóstico, preventivo y terapéutico. */
  plan: string;
  /** XII. Plan educativo: indicaciones al paciente. */
  indicaciones?: string;
}

export interface PropsConsultaClinica extends ContenidoConsulta {
  id: string;
  pacienteId: string;
  medicoId: string;
  autorUsuarioId: string;
  citaId?: string;
  fecha: Date;
  creadaEn: Date;
  actualizadaEn: Date;
}

/** Rangos fisiológicamente posibles: detectan errores de digitación, no diagnostican. */
const RANGOS: Record<Exclude<keyof SignosVitales, 'tensionArterial'>, [number, number, string]> = {
  frecuenciaCardiaca: [20, 250, 'La frecuencia cardíaca'],
  frecuenciaRespiratoria: [4, 80, 'La frecuencia respiratoria'],
  temperatura: [30, 45, 'La temperatura'],
  saturacionOxigeno: [50, 100, 'La saturación de oxígeno'],
  peso: [0.3, 400, 'El peso'],
  talla: [20, 250, 'La talla'],
  circunferenciaAbdominal: [30, 250, 'La circunferencia abdominal'],
};

const MAX_TEXTO_LARGO = 5000;

function validarSignos(s: SignosVitales): SignosVitales {
  const limpios: SignosVitales = {};
  if (s.tensionArterial?.trim()) {
    const ta = s.tensionArterial.replace(/\s+/g, '');
    const m = /^(\d{2,3})\/(\d{2,3})$/.exec(ta);
    asegurar(m, 'La tensión arterial debe tener el formato sistólica/diastólica, p. ej. 120/80');
    const [sis, dia] = [Number(m[1]), Number(m[2])];
    asegurar(sis >= 50 && sis <= 260 && dia >= 30 && dia <= 160 && sis > dia, 'La tensión arterial está fuera de rango');
    limpios.tensionArterial = `${sis}/${dia}`;
  }
  for (const [campo, [min, max, nombre]] of Object.entries(RANGOS) as [keyof typeof RANGOS, [number, number, string]][]) {
    const valor = s[campo];
    if (valor === undefined || valor === null) continue;
    asegurar(typeof valor === 'number' && Number.isFinite(valor), `${nombre} debe ser un número`);
    asegurar(valor >= min && valor <= max, `${nombre} debe estar entre ${min} y ${max}`);
    limpios[campo] = valor;
  }
  return limpios;
}

function texto(valor: string | undefined, nombre: string, requerido = false): string {
  const t = (valor ?? '').trim();
  if (requerido) asegurar(t, `${nombre} es obligatorio`);
  asegurar(t.length <= MAX_TEXTO_LARGO, `${nombre} admite máximo ${MAX_TEXTO_LARGO} caracteres`);
  return t;
}

function validarContenido(c: ContenidoConsulta): ContenidoConsulta {
  const diagnosticos = [...new Set((c.impresionDiagnostica ?? []).map((d) => d.trim()).filter(Boolean))];
  asegurar(diagnosticos.length > 0, 'Registra al menos una impresión diagnóstica');
  asegurar(diagnosticos.length <= 15 && diagnosticos.every((d) => d.length <= 300), 'Máximo 15 diagnósticos de 300 caracteres');
  const problemas = [...new Set((c.listaProblemas ?? []).map((d) => d.trim()).filter(Boolean))];
  asegurar(problemas.length <= 15 && problemas.every((d) => d.length <= 300), 'Máximo 15 problemas de 300 caracteres');
  return {
    motivoConsulta: texto(c.motivoConsulta, 'El motivo de consulta', true),
    estimuloIatrotropico: texto(c.estimuloIatrotropico, 'El estímulo iatrotrópico') || undefined,
    enfermedadActual: texto(c.enfermedadActual, 'La enfermedad actual', true),
    revisionPorSistemas: texto(c.revisionPorSistemas, 'La revisión por sistemas') || undefined,
    condicionesGenerales: texto(c.condicionesGenerales, 'Las condiciones generales') || undefined,
    signosVitales: validarSignos(c.signosVitales ?? {}),
    examenFisico: texto(c.examenFisico, 'El examen físico'),
    listaProblemas: problemas,
    impresionDiagnostica: diagnosticos,
    examenes: texto(c.examenes, 'Los exámenes') || undefined,
    plan: texto(c.plan, 'El plan', true),
    indicaciones: texto(c.indicaciones, 'Las indicaciones') || undefined,
  };
}

/**
 * «Entity» ConsultaClinica: la historia clínica de un encuentro médico
 * (motivo, enfermedad actual, examen físico, impresión diagnóstica y plan).
 * Solo la escribe un médico; queda fija pasadas 24 h para preservar su valor legal.
 */
export class ConsultaClinica implements PropsConsultaClinica {
  id: string;
  pacienteId: string;
  medicoId: string;
  autorUsuarioId: string;
  citaId?: string;
  fecha: Date;
  motivoConsulta: string;
  estimuloIatrotropico?: string;
  enfermedadActual: string;
  revisionPorSistemas?: string;
  condicionesGenerales?: string;
  signosVitales: SignosVitales;
  examenFisico: string;
  listaProblemas: string[];
  impresionDiagnostica: string[];
  examenes?: string;
  plan: string;
  indicaciones?: string;
  creadaEn: Date;
  actualizadaEn: Date;

  constructor(props: PropsConsultaClinica) {
    Object.assign(this, props);
  }

  static registrar(
    datos: ContenidoConsulta & { pacienteId: string; medicoId: string; autorUsuarioId: string; citaId?: string; fecha: Date },
    ahora: Date,
  ): ConsultaClinica {
    asegurar(!isNaN(datos.fecha.getTime()), 'Fecha de la consulta inválida');
    asegurar(datos.fecha.getTime() <= ahora.getTime() + HORA_MS, 'La fecha de la consulta no puede ser futura');
    return new ConsultaClinica({
      id: generarId(),
      pacienteId: datos.pacienteId,
      medicoId: datos.medicoId,
      autorUsuarioId: datos.autorUsuarioId,
      citaId: datos.citaId,
      fecha: datos.fecha,
      ...validarContenido(datos),
      creadaEn: ahora,
      actualizadaEn: ahora,
    });
  }

  puedeEditar(medicoId: string | undefined, ahora: Date): boolean {
    return !!medicoId && medicoId === this.medicoId && ahora.getTime() - this.creadaEn.getTime() <= HORAS_EDICION_CONSULTA * HORA_MS;
  }

  corregir(medicoId: string | undefined, contenido: ContenidoConsulta, ahora: Date): void {
    asegurar(medicoId === this.medicoId, 'Solo el médico que registró la consulta puede corregirla');
    asegurar(this.puedeEditar(medicoId, ahora), `La historia de la consulta solo se puede corregir durante ${HORAS_EDICION_CONSULTA} horas`);
    Object.assign(this, validarContenido(contenido));
    this.actualizadaEn = ahora;
  }

  /** Índice de masa corporal (kg/m²) con un decimal, si hay peso y talla. */
  get imc(): number | undefined {
    const { peso, talla } = this.signosVitales;
    if (!peso || !talla) return undefined;
    return Math.round((peso / (talla / 100) ** 2) * 10) / 10;
  }

  contenido(): ContenidoConsulta {
    return {
      motivoConsulta: this.motivoConsulta,
      estimuloIatrotropico: this.estimuloIatrotropico,
      enfermedadActual: this.enfermedadActual,
      revisionPorSistemas: this.revisionPorSistemas,
      condicionesGenerales: this.condicionesGenerales,
      signosVitales: this.signosVitales,
      examenFisico: this.examenFisico,
      listaProblemas: this.listaProblemas,
      impresionDiagnostica: this.impresionDiagnostica,
      examenes: this.examenes,
      plan: this.plan,
      indicaciones: this.indicaciones,
    };
  }
}
