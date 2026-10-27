import { DIA_MS, HORA_MS } from '../../../shared/domain/reloj';

/** Anticipación de los recordatorios de cita (criterio 1: 24 horas y 1 hora antes). */
export const ANTICIPOS_CITA_HORAS = [24, 1] as const;

/** Recordatorios de una orden de exámenes que sigue pendiente: 1, 3 y 7 días después de indicada. */
export const DIAS_RECORDATORIO_ORDEN = [1, 3, 7] as const;

/** Tope de tomas por medicamento, para no generar miles con frecuencias raras. */
const MAXIMO_TOMAS = 400;

const PALABRAS_NUMERO: Record<string, number> = { una: 1, un: 1, uno: 1, dos: 2, tres: 3, cuatro: 4, seis: 6 };

/**
 * Interpreta la frecuencia escrita por el médico en el récipe y devuelve las
 * horas entre tomas. Acepta las formas habituales: "cada 8 h", "cada 8 horas",
 * "c/12h", "cada 24 h", "una vez al día", "dos veces al día", "diario",
 * "cada 2 días". Devuelve `null` si no la entiende (p. ej. "si hay dolor"):
 * en ese caso no se programan recordatorios para ese medicamento.
 */
export function horasEntreTomas(frecuencia: string): number | null {
  const f = frecuencia
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

  if (/\b(si|en caso de)\b.*\b(dolor|fiebre|necesario|necesita)/.test(f) || /\bsos\b|a demanda/.test(f)) return null;

  const cadaHoras = f.match(/(?:cada|c\/)\s*(\d+)\s*(?:h\b|hs\b|hrs?\b|horas?\b)/);
  if (cadaHoras) return validas(Number(cadaHoras[1]));

  const cadaDias = f.match(/cada\s*(\d+)\s*dias?\b/);
  if (cadaDias) return validas(Number(cadaDias[1]) * 24);

  const vecesAlDia = f.match(/(\d+|una|un|uno|dos|tres|cuatro|seis)\s*(?:vez|veces)\s*(?:al|por)\s*dia/);
  if (vecesAlDia) {
    const veces = Number(vecesAlDia[1]) || PALABRAS_NUMERO[vecesAlDia[1]];
    return veces ? validas(24 / veces) : null;
  }

  if (/\bdiari[oa]\b|\bcada dia\b|\bal dia\b/.test(f)) return 24;
  if (/\bsemanal\b|cada semana/.test(f)) return 24 * 7;
  return null;
}

const validas = (horas: number): number | null => (Number.isFinite(horas) && horas >= 1 && horas <= 24 * 30 ? horas : null);

/** La primera toma se recuerda en la siguiente hora en punto después de emitido el récipe. */
export function primeraToma(emitidoEn: Date): Date {
  return new Date(Math.ceil(emitidoEn.getTime() / HORA_MS) * HORA_MS);
}

/** Todas las tomas de un medicamento durante el tratamiento. */
export function tomasDelTratamiento(emitidoEn: Date, item: { frecuencia: string; duracionDias: number }): Date[] {
  const cada = horasEntreTomas(item.frecuencia);
  if (!cada || item.duracionDias <= 0) return [];
  const inicio = primeraToma(emitidoEn).getTime();
  const fin = emitidoEn.getTime() + item.duracionDias * DIA_MS;
  const tomas: Date[] = [];
  for (let t = inicio; t < fin && tomas.length < MAXIMO_TOMAS; t += cada * HORA_MS) tomas.push(new Date(t));
  return tomas;
}

/** `desde` excluido, `hasta` incluido: dos ventanas seguidas nunca cuentan dos veces el mismo instante. */
export const enVentana = (fecha: Date, desde: Date, hasta: Date): boolean =>
  fecha.getTime() > desde.getTime() && fecha.getTime() <= hasta.getTime();
