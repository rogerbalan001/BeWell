import { ArchivosController } from '../../src/shared/interface/http/archivos.controller';

describe('ArchivosController — descarga por URL firmada', () => {
  it('envía el archivo con X-Content-Type-Options: nosniff', async () => {
    const almacenamiento = {
      resolverTokenLectura: (t: string) => `ruta/${t}`,
      leer: async () => ({ contenido: Buffer.from('hola'), tipoMime: 'image/png', nombreOriginal: 'resultado.png' }),
    };
    const headers: Record<string, string> = {};
    let enviado: Buffer | undefined;
    const res = { setHeader: (k: string, v: string) => (headers[k] = v), send: (b: Buffer) => (enviado = b) };
    await new ArchivosController(almacenamiento as never).descargar('tok', res as never);
    expect(headers['X-Content-Type-Options']).toBe('nosniff');
    expect(headers['Content-Type']).toBe('image/png');
    expect(enviado?.toString()).toBe('hola');
  });
});
