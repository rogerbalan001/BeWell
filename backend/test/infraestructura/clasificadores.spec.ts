import { ClasificadorGeminiAdapter } from '../../src/modules/examenes/infrastructure/clasificador-gemini.adapter';
import { ClasificadorSimuladoAdapter } from '../../src/modules/examenes/infrastructure/clasificador-simulado.adapter';

const pdf = { contenido: Buffer.from('%PDF-1.4 prueba'), tipoMime: 'application/pdf', nombre: 'resultado.pdf' };

function gemini(respuesta: { status?: number; json?: unknown; error?: Error }, clave = 'clave-de-prueba') {
  const llamadas: { url: string; headers: Record<string, string>; cuerpo: Record<string, unknown> }[] = [];
  const fetch = async (url: string, init: { headers: Record<string, string>; body: string }) => {
    llamadas.push({ url, headers: init.headers, cuerpo: JSON.parse(init.body) });
    if (respuesta.error) throw respuesta.error;
    const status = respuesta.status ?? 200;
    return { ok: status < 300, status, text: async () => JSON.stringify(respuesta.json ?? {}) };
  };
  const config = { get: (k: string) => ({ GEMINI_API_KEY: clave, GEMINI_MODELO: '' })[k] };
  return { adapter: new ClasificadorGeminiAdapter(config as never, fetch), llamadas };
}

const respuestaGemini = (datos: unknown) => ({ candidates: [{ content: { parts: [{ text: JSON.stringify(datos) }] } }] });

describe('ClasificadorGeminiAdapter', () => {
  it('envía el archivo y el catálogo, y devuelve la sugerencia', async () => {
    const { adapter, llamadas } = gemini({ json: respuestaGemini({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', confianza: 0.93 }) });
    const r = await adapter.clasificar(pdf, { analitos: ['Colesterol total'] });
    expect(r).toEqual({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', confianza: 0.93 });
    const [llamada] = llamadas;
    expect(llamada.url).toContain('/models/gemini-2.5-flash:generateContent');
    expect(llamada.headers['x-goog-api-key']).toBe('clave-de-prueba');
    const partes = (llamada.cuerpo.contents as { parts: Record<string, unknown>[] }[])[0].parts;
    expect(partes[1]).toEqual({ inline_data: { mime_type: 'application/pdf', data: pdf.contenido.toString('base64') } });
    expect(String(partes[0].text)).toContain('Perfil lipídico');
    expect(String(partes[0].text)).toContain('Colesterol total');
    expect((llamada.cuerpo.generationConfig as Record<string, unknown>).responseMimeType).toBe('application/json');
  });

  it('con baja confianza o sin tipo no sugiere nada', async () => {
    expect(await gemini({ json: respuestaGemini({ categoria: 'Otro', tipo: '', confianza: 0 }) }).adapter.clasificar(pdf, { analitos: [] })).toBeNull();
    expect(await gemini({ json: respuestaGemini({ categoria: 'Otro', tipo: 'Algo', confianza: 0.2 }) }).adapter.clasificar(pdf, { analitos: [] })).toBeNull();
  });

  it('si Gemini falla, responde con error o no devuelve JSON, no lanza: devuelve null', async () => {
    expect(await gemini({ status: 429, json: { error: { message: 'cuota' } } }).adapter.clasificar(pdf, { analitos: [] })).toBeNull();
    expect(await gemini({ error: new Error('sin red') }).adapter.clasificar(pdf, { analitos: [] })).toBeNull();
    expect(await gemini({ json: { candidates: [{ content: { parts: [{ text: 'no es json' }] } }] } }).adapter.clasificar(pdf, { analitos: [] })).toBeNull();
  });

  it('sin GEMINI_API_KEY no llama a Gemini', async () => {
    const { adapter, llamadas } = gemini({ json: {} }, '');
    expect(await adapter.clasificar(pdf, { analitos: [] })).toBeNull();
    expect(llamadas).toHaveLength(0);
  });
});

describe('ClasificadorSimuladoAdapter (sin IA)', () => {
  const c = new ClasificadorSimuladoAdapter();

  it('deduce el tipo por los analitos que reconoció el OCR', async () => {
    expect(await c.clasificar(pdf, { analitos: ['Colesterol total', 'Triglicéridos'] })).toMatchObject({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico' });
    expect(await c.clasificar(pdf, { analitos: ['Leucocitos', 'Plaquetas'] })).toMatchObject({ tipo: 'Hematología completa' });
    expect(await c.clasificar(pdf, { analitos: ['TSH'] })).toMatchObject({ tipo: 'Perfil tiroideo (TSH, T4 libre)' });
  });

  it('si no hay analitos, usa el nombre del archivo o el título', async () => {
    expect(await c.clasificar({ ...pdf, nombre: 'rx_torax_2026.jpg' }, { analitos: [] })).toMatchObject({ categoria: 'Imagenología', tipo: 'Radiografía de tórax' });
    expect(await c.clasificar(pdf, { analitos: [], tituloPaciente: 'Electrocardiograma de control' })).toMatchObject({ categoria: 'Cardiología' });
  });

  it('si no reconoce nada devuelve null', async () => {
    expect(await c.clasificar({ ...pdf, nombre: 'IMG_2031.jpg' }, { analitos: [] })).toBeNull();
  });
});
