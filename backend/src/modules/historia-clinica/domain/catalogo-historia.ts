import { asegurar } from '../../../shared/domain/errores';

/**
 * Catálogo del modelo de historia clínica integral (secciones I a XII).
 * Define las claves que acepta cada parte de la historia; las etiquetas y
 * guías de interrogatorio viven en la app.
 */

/** Identificación que no está en el perfil del paciente. */
export const CLAVES_IDENTIFICACION = [
  'lugarNacimiento',
  'procedencia',
  'nacionalidad',
  'estadoCivil',
  'nivelInstruccion',
  'ocupacion',
  'religion',
  'direccion',
  'seguridadSocial',
  'contactoEmergencia',
  'telefonoEmergencia',
] as const;

/** III. Antecedentes personales (en el orden del modelo; los ginecobstétricos van aparte). */
export const LISTAS_PERSONALES = [
  'inmunizaciones',
  'infancia',
  'alergicos',
  'parasitosis',
  'infecciones',
  'transmisionSexual',
  'epidemiologicos',
  'patologicos',
  'quirurgicos',
  'traumatologicos',
  'psiquiatricos',
  'laborales',
  'intoxicaciones',
  'radiaciones',
  'transfusionales',
] as const;

/** IV. Antecedentes familiares, por tipo. */
export const TIPOS_FAMILIARES = [
  'alergicos',
  'infecciosos',
  'metabolicos',
  'neoplasias',
  'cardiovasculares',
  'mentales',
  'hematologicos',
  'inmunologicos',
  'articulares',
  'otros',
] as const;

/** V. Historia personal y social (los medicamentos son una lista aparte). */
export const CLAVES_HABITOS = [
  'alcohol',
  'tabaco',
  'cafe',
  'drogas',
  'drogasLicitas',
  'sexuales',
  'actividadFisica',
  'sueno',
  'alimentacion',
  'otraActividad',
  'vivienda',
  'otros',
] as const;

/** VI. Revisión por aparatos y sistemas. */
export const SISTEMAS_REVISION = [
  'general',
  'piel',
  'cabeza',
  'ojos',
  'oidos',
  'nariz',
  'bocaFaringe',
  'cuello',
  'mamas',
  'cardiovascular',
  'respiratorio',
  'digestivo',
  'urinario',
  'ginecologico',
  'osteoarticular',
  'neurologico',
  'endocrino',
  'inmunologico',
  'hematologico',
  'psiquiatrico',
] as const;

/** VII. Examen físico por regiones. */
export const REGIONES_EXAMEN = [
  'piel',
  'cabeza',
  'ojos',
  'oidos',
  'nariz',
  'bocaFaringe',
  'cuello',
  'torax',
  'respiratorio',
  'cardiovascular',
  'mamas',
  'abdomen',
  'lumbar',
  'rectal',
  'ginecologico',
  'genitalesMasculinos',
  'extremidades',
  'osteomuscular',
  'columna',
  'neurologico',
  'mental',
  'ganglios',
] as const;

/** XI. Exámenes. */
export const TIPOS_EXAMENES = ['laboratorio', 'imagenologicos', 'morfologicos', 'otros'] as const;

export type Textos<K extends string> = Partial<Record<K, string>>;

/** Conserva solo las claves del catálogo con texto, sin espacios sobrantes y con un largo máximo. */
export function limpiarTextos<K extends string>(valores: unknown, claves: readonly K[], max: number, nombre: string): Textos<K> {
  const origen = (valores && typeof valores === 'object' ? valores : {}) as Record<string, unknown>;
  const limpios: Textos<K> = {};
  for (const k of claves) {
    const v = origen[k];
    if (v === undefined || v === null) continue;
    asegurar(typeof v === 'string', `${nombre}: el campo ${k} debe ser texto`);
    const t = v.trim();
    if (!t) continue;
    asegurar(t.length <= max, `${nombre}: cada campo admite máximo ${max} caracteres`);
    limpios[k] = t;
  }
  return limpios;
}
