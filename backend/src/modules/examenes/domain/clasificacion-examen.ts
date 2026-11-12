import { CATALOGO_EXAMENES } from './catalogo-examenes';

/** Categoría para lo que no encaja en el catálogo. */
export const CATEGORIA_OTRO = 'Otro';

/** Categorías que puede sugerir la IA o elegir el paciente: las del catálogo más "Otro". */
export const CATEGORIAS_EXAMEN: string[] = [...CATALOGO_EXAMENES.map((c) => c.categoria), CATEGORIA_OTRO];

/** Quién definió la categoría y el tipo del examen. */
export type OrigenClasificacion = 'IA' | 'PACIENTE';

/** Categoría y tipo de un examen (p. ej. "Laboratorio clínico" / "Perfil lipídico"). */
export interface ClasificacionExamen {
  categoria: string;
  tipo: string;
  /** 0–1. Solo para sugerencias de la IA; ausente si lo eligió el paciente. */
  confianza?: number;
  origen: OrigenClasificacion;
}

const normalizar = (t: string) =>
  t
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();

/** Devuelve la categoría del catálogo que coincide (sin importar tildes ni mayúsculas) o "Otro". */
export function categoriaValida(categoria: string | undefined): string {
  const n = normalizar(categoria ?? '');
  return CATEGORIAS_EXAMEN.find((c) => normalizar(c) === n) ?? CATEGORIA_OTRO;
}

/** Si el tipo coincide con un examen del catálogo, usa el nombre del catálogo; si no, lo deja como vino. */
export function tipoNormalizado(tipo: string): string {
  const n = normalizar(tipo);
  return CATALOGO_EXAMENES.flatMap((c) => c.examenes).find((e) => normalizar(e) === n) ?? tipo.trim();
}

/** Categoría del catálogo a la que pertenece un tipo conocido, si la hay. */
export function categoriaDeTipo(tipo: string): string | undefined {
  const n = normalizar(tipo);
  return CATALOGO_EXAMENES.find((c) => c.examenes.some((e) => normalizar(e) === n))?.categoria;
}
