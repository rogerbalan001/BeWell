import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClasificadorExamen, PistasClasificacion, SugerenciaClasificacion } from '../application/clasificador-examen';
import { CATALOGO_EXAMENES } from '../domain/catalogo-examenes';
import { CATEGORIAS_EXAMEN } from '../domain/clasificacion-examen';

export const MODELO_GEMINI_POR_DEFECTO = 'gemini-2.5-flash';
const URL_API = 'https://generativelanguage.googleapis.com/v1beta/models';
/** Tiempo máximo de espera: después de esto el examen se guarda sin sugerencia. */
const TIEMPO_LIMITE_MS = 20_000;
/** Por debajo de esta confianza no se sugiere nada y el paciente elige. */
export const CONFIANZA_MINIMA = 0.35;

type Fetch = (url: string, init: { method: string; headers: Record<string, string>; body: string; signal?: AbortSignal }) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

interface RespuestaGemini {
  candidates?: { content?: { parts?: { text?: string }[] } }[];
}

/**
 * Clasificador con Google Gemini (API generateContent). Envía la foto o el PDF
 * con el catálogo de Bewell y pide una respuesta JSON con categoría, tipo y
 * confianza. Variables: GEMINI_API_KEY (obligatoria) y GEMINI_MODELO
 * (opcional, por defecto gemini-2.5-flash). Se crea en ExamenesModule según
 * IA_EXAMENES=gemini.
 */
export class ClasificadorGeminiAdapter extends ClasificadorExamen {
  private readonly logger = new Logger('ClasificadorGemini');
  private readonly clave: string;
  private readonly modelo: string;
  private readonly fetch: Fetch;

  constructor(config: ConfigService, fetchFn?: Fetch) {
    super();
    this.clave = config.get<string>('GEMINI_API_KEY') ?? '';
    this.modelo = config.get<string>('GEMINI_MODELO') || MODELO_GEMINI_POR_DEFECTO;
    this.fetch = fetchFn ?? (globalThis.fetch as unknown as Fetch);
    if (!this.clave) this.logger.warn('IA_EXAMENES=gemini pero falta GEMINI_API_KEY: los exámenes se guardarán sin sugerencia.');
  }

  async clasificar(archivo: { contenido: Buffer; tipoMime: string; nombre: string }, pistas: PistasClasificacion): Promise<SugerenciaClasificacion | null> {
    if (!this.clave) return null;
    const control = new AbortController();
    const temporizador = setTimeout(() => control.abort(), TIEMPO_LIMITE_MS);
    try {
      const r = await this.fetch(`${URL_API}/${this.modelo}:generateContent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': this.clave },
        body: JSON.stringify(this.cuerpo(archivo, pistas)),
        signal: control.signal,
      });
      const texto = await r.text();
      if (!r.ok) {
        this.logger.warn(`Gemini respondió ${r.status}: ${texto.slice(0, 200)}`);
        return null;
      }
      return this.interpretar(JSON.parse(texto) as RespuestaGemini);
    } catch (e) {
      this.logger.warn(`No se pudo clasificar el examen con Gemini: ${(e as Error).message}`);
      return null;
    } finally {
      clearTimeout(temporizador);
    }
  }

  private cuerpo(archivo: { contenido: Buffer; tipoMime: string }, pistas: PistasClasificacion) {
    const catalogo = CATALOGO_EXAMENES.map((c) => `- ${c.categoria}: ${c.examenes.join('; ')}`).join('\n');
    const instrucciones = [
      'Eres un asistente que clasifica documentos de exámenes médicos para una app de salud en Venezuela.',
      'Mira el documento adjunto y responde solo con la categoría y el tipo de examen.',
      `Categorías válidas: ${CATEGORIAS_EXAMEN.join(', ')}.`,
      'Si el examen está en este catálogo, usa exactamente su nombre como tipo:',
      catalogo,
      'Si no está en el catálogo, usa un nombre corto en español (por ejemplo "Prueba de embarazo") y la categoría que mejor encaje, u "Otro".',
      'confianza va de 0 a 1. Si el documento no es un examen médico o no se puede leer, responde con tipo vacío y confianza 0.',
      pistas.analitos.length ? `El OCR ya reconoció estos analitos: ${pistas.analitos.join(', ')}.` : '',
      pistas.tituloPaciente ? `El paciente lo llamó: "${pistas.tituloPaciente}".` : '',
    ]
      .filter(Boolean)
      .join('\n');
    return {
      contents: [
        {
          role: 'user',
          parts: [{ text: instrucciones }, { inline_data: { mime_type: archivo.tipoMime, data: archivo.contenido.toString('base64') } }],
        },
      ],
      generationConfig: {
        temperature: 0,
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            categoria: { type: 'STRING', enum: CATEGORIAS_EXAMEN },
            tipo: { type: 'STRING' },
            confianza: { type: 'NUMBER' },
          },
          required: ['categoria', 'tipo', 'confianza'],
        },
      },
    };
  }

  private interpretar(r: RespuestaGemini): SugerenciaClasificacion | null {
    const texto = r.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
    if (!texto.trim()) return null;
    let datos: { categoria?: string; tipo?: string; confianza?: number };
    try {
      datos = JSON.parse(texto) as typeof datos;
    } catch {
      this.logger.warn(`Gemini no devolvió JSON válido: ${texto.slice(0, 120)}`);
      return null;
    }
    const tipo = (datos.tipo ?? '').trim();
    const confianza = Math.min(Math.max(Number(datos.confianza) || 0, 0), 1);
    if (!tipo || confianza < CONFIANZA_MINIMA) return null;
    return { categoria: datos.categoria ?? '', tipo, confianza };
  }
}
