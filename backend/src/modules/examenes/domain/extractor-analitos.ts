import { ResultadoAnalito } from './examen-medico';

/** Valor extraído de un documento, todavía sin revisión del paciente ni del médico. */
export type AnalitoExtraido = Omit<ResultadoAnalito, 'validadoPorMedico'>;

interface AnalitoConocido {
  nombre: string;
  /** Se prueba contra la línea en minúsculas y sin tildes. */
  patron: RegExp;
  /** Si la línea coincide con este patrón, el analito NO aplica (p. ej. "colesterol HDL" no es colesterol total). */
  excluir?: RegExp;
  unidadPorDefecto: string;
  /** Conteos que los laboratorios escriben con punto de miles (250.000). */
  esConteo?: boolean;
}

/**
 * Catálogo de analitos que la app sabe reconocer. El orden importa: los
 * nombres más específicos van antes que los generales (HbA1c antes que
 * hemoglobina; HDL y LDL antes que colesterol total).
 */
export const ANALITOS_CONOCIDOS: AnalitoConocido[] = [
  { nombre: 'Hemoglobina glicosilada (HbA1c)', patron: /\bhba1c\b|hemoglobina gl[iu]c?osilada|\ba1c\b/, unidadPorDefecto: '%' },
  { nombre: 'Glucosa en ayunas', patron: /\bglucosa\b|\bglicemia\b|\bglucemia\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Colesterol HDL', patron: /\bhdl\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Colesterol VLDL', patron: /\bvldl\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Colesterol LDL', patron: /\bldl\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Colesterol total', patron: /\bcolesterol\b/, excluir: /\b(hdl|ldl|vldl)\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Triglicéridos', patron: /\btrigliceridos?\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Hemoglobina', patron: /\bhemoglobina\b|\bhgb\b/, excluir: /gl[iu]c?osilada|\ba1c\b/, unidadPorDefecto: 'g/dL' },
  { nombre: 'Hematocrito', patron: /\bhematocrito\b|\bhto\b|\bhct\b/, unidadPorDefecto: '%' },
  { nombre: 'Leucocitos', patron: /\bleucocitos\b|globulos blancos|\bwbc\b/, unidadPorDefecto: '/mm³', esConteo: true },
  { nombre: 'Plaquetas', patron: /\bplaquetas\b|\bplt\b/, unidadPorDefecto: '/mm³', esConteo: true },
  { nombre: 'Creatinina', patron: /\bcreatinina\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Urea', patron: /\burea\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'Ácido úrico', patron: /\bacido urico\b/, unidadPorDefecto: 'mg/dL' },
  { nombre: 'TSH', patron: /\btsh\b|\btirotropina\b/, unidadPorDefecto: 'µUI/mL' },
  { nombre: 'TGO (AST)', patron: /\btgo\b|\bast\b|\baspartato\b/, unidadPorDefecto: 'U/L' },
  { nombre: 'TGP (ALT)', patron: /\btgp\b|\balt\b|\balanina\b/, unidadPorDefecto: 'U/L' },
  { nombre: 'Vitamina D (25-OH)', patron: /\bvitamina d\b|\b25.?oh\b/, unidadPorDefecto: 'ng/mL' },
];

const UNIDADES: [RegExp, string][] = [
  [/^mg\s*\/\s*dl\b/, 'mg/dL'],
  [/^g\s*\/\s*dl\b/, 'g/dL'],
  [/^mmol\s*\/\s*l\b/, 'mmol/L'],
  [/^ng\s*\/\s*ml\b/, 'ng/mL'],
  [/^[uµ]u?i\s*\/\s*ml\b/, 'µUI/mL'],
  [/^u\s*\/\s*l\b/, 'U/L'],
  [/^x\s*10\s*\^?\s*3\s*\/\s*[uµ]l\b/, '×10³/µL'],
  [/^\/\s*mm\s*(3|³)/, '/mm³'],
  [/^\/\s*[uµ]l\b/, '/µL'],
  [/^%/, '%'],
];

/** Un número que no forma parte de una palabra ("HbA1c") ni de "25-OH". */
const NUMERO = /(?<![a-z\d.,])\d+(?:[.,]\d+)*(?!\d|-oh)/;

/** Minúsculas y sin tildes, para comparar sin depender de cómo escribió el laboratorio. */
export function normalizar(texto: string): string {
  return texto
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[ \t]+/g, ' ');
}

/** Convierte "14,2", "1.234,5" o "250.000" a notación con punto decimal. */
export function normalizarNumero(token: string, esConteo = false): string {
  if (esConteo && /^\d{1,3}(\.\d{3})+$/.test(token)) return token.replace(/\./g, '');
  if (token.includes('.') && token.includes(',')) return token.replace(/\./g, '').replace(',', '.');
  return token.replace(',', '.');
}

function detectarUnidad(resto: string): string | undefined {
  const texto = resto.trimStart();
  for (const [patron, unidad] of UNIDADES) if (patron.test(texto)) return unidad;
  return undefined;
}

function detectarRango(resto: string): string | undefined {
  const entre = resto.match(/(\d+(?:[.,]\d+)?)\s*(?:-|–|—|a)\s*(\d+(?:[.,]\d+)?)/);
  if (entre) return `${normalizarNumero(entre[1])} – ${normalizarNumero(entre[2])}`;
  const limite = resto.match(/(<=?|>=?|≤|≥|menor (?:a|de)|mayor (?:a|de)|hasta)\s*(\d+(?:[.,]\d+)?)/);
  if (!limite) return undefined;
  const signo = /^(<|≤|menor|hasta)/.test(limite[1]) ? '<' : '>';
  return `${signo} ${normalizarNumero(limite[2])}`;
}

/**
 * Extrae los analitos reconocibles de un texto obtenido por OCR o de un PDF
 * digital. Lee línea por línea: nombre del analito, primer número después
 * del nombre (el valor), la unidad pegada al valor y, si aparece, el rango
 * de referencia. Devuelve un analito por nombre (el primero que encuentra).
 *
 * `confianzaTexto` (0–1) es la confianza del motor de OCR sobre el texto; se
 * combina con lo completa que está la línea para calcular `confianzaOcr`.
 */
export function extraerAnalitos(texto: string, confianzaTexto = 1): AnalitoExtraido[] {
  const encontrados = new Map<string, AnalitoExtraido>();
  for (const lineaOriginal of texto.split(/\r?\n/)) {
    const linea = normalizar(lineaOriginal).trim();
    if (!linea) continue;
    for (const analito of ANALITOS_CONOCIDOS) {
      if (encontrados.has(analito.nombre)) continue;
      if (analito.excluir?.test(linea)) continue;
      const coincidencia = analito.patron.exec(linea);
      if (!coincidencia) continue;

      const despues = linea.slice(coincidencia.index + coincidencia[0].length);
      const numero = NUMERO.exec(despues);
      if (!numero) continue;

      const valor = normalizarNumero(numero[0], analito.esConteo);
      const resto = despues.slice(numero.index + numero[0].length);
      const unidad = detectarUnidad(resto);
      const rangoReferencia = detectarRango(resto);

      const completitud = 0.6 + (unidad ? 0.2 : 0) + (rangoReferencia ? 0.15 : 0);
      const confianza = Math.min(0.99, Math.max(0.3, completitud * Math.min(1, Math.max(0, confianzaTexto))));

      encontrados.set(analito.nombre, {
        analito: analito.nombre,
        valor,
        unidad: unidad ?? analito.unidadPorDefecto,
        rangoReferencia,
        confianzaOcr: Math.round(confianza * 100) / 100,
      });
      break;
    }
  }
  return [...encontrados.values()];
}
