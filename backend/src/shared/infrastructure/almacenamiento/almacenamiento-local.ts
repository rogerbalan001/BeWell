import { createCipheriv, createDecipheriv, createHmac, randomBytes, timingSafeEqual } from 'crypto';
import { promises as fs } from 'fs';
import { join, normalize } from 'path';
import { AlmacenamientoArchivos, ArchivoGuardado, ArchivoLeido } from '../../application/almacenamiento-archivos';
import { NoEncontradoError, NoAutenticadoError } from '../../domain/errores';
import { generarId } from '../../domain/id';

interface Metadatos {
  tipoMime: string;
  nombreOriginal: string;
  tamanoBytes: number;
}

/**
 * Adapter de almacenamiento de objetos sobre disco local, con cifrado en
 * reposo (AES-256-GCM) y URL de lectura firmadas con HMAC y vencimiento.
 * Reemplazable por un adapter S3 implementando el mismo puerto.
 */
export class AlmacenamientoLocal extends AlmacenamientoArchivos {
  constructor(
    private readonly directorio: string,
    private readonly llaveCifrado: Buffer,
    private readonly secretoUrl: string,
    private readonly urlPublicaApi: string,
  ) {
    super();
  }

  async guardar(carpeta: string, contenido: Buffer, tipoMime: string, nombreOriginal: string): Promise<ArchivoGuardado> {
    const ruta = `${carpeta.replace(/[^a-zA-Z0-9_-]/g, '')}/${generarId()}`;
    const destino = this.rutaAbsoluta(ruta);
    await fs.mkdir(join(destino, '..'), { recursive: true });
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.llaveCifrado, iv);
    const cifrado = Buffer.concat([cipher.update(contenido), cipher.final()]);
    await fs.writeFile(`${destino}.bin`, Buffer.concat([iv, cipher.getAuthTag(), cifrado]));
    const meta: Metadatos = { tipoMime, nombreOriginal, tamanoBytes: contenido.length };
    await fs.writeFile(`${destino}.json`, JSON.stringify(meta));
    return { ruta, ...meta };
  }

  async leer(ruta: string): Promise<ArchivoLeido> {
    const destino = this.rutaAbsoluta(ruta);
    try {
      const [datos, metaRaw] = await Promise.all([fs.readFile(`${destino}.bin`), fs.readFile(`${destino}.json`, 'utf8')]);
      const meta = JSON.parse(metaRaw) as Metadatos;
      const decipher = createDecipheriv('aes-256-gcm', this.llaveCifrado, datos.subarray(0, 12));
      decipher.setAuthTag(datos.subarray(12, 28));
      const contenido = Buffer.concat([decipher.update(datos.subarray(28)), decipher.final()]);
      return { contenido, tipoMime: meta.tipoMime, nombreOriginal: meta.nombreOriginal };
    } catch {
      throw new NoEncontradoError('Archivo');
    }
  }

  generarUrlLectura(ruta: string, segundosVigencia = 300): string {
    const carga = Buffer.from(JSON.stringify({ r: ruta, e: Date.now() + segundosVigencia * 1000 })).toString('base64url');
    return `${this.urlPublicaApi}/archivos/${carga}.${this.firmar(carga)}`;
  }

  resolverTokenLectura(token: string): string {
    const [carga, firma] = token.split('.');
    if (!carga || !firma) throw new NoAutenticadoError('URL inválida');
    const esperada = Buffer.from(this.firmar(carga));
    const recibida = Buffer.from(firma);
    if (esperada.length !== recibida.length || !timingSafeEqual(esperada, recibida)) {
      throw new NoAutenticadoError('Firma de URL inválida');
    }
    const { r, e } = JSON.parse(Buffer.from(carga, 'base64url').toString('utf8')) as { r: string; e: number };
    if (Date.now() > e) throw new NoAutenticadoError('La URL de lectura venció');
    return r;
  }

  private firmar(carga: string): string {
    return createHmac('sha256', this.secretoUrl).update(carga).digest('base64url');
  }

  private rutaAbsoluta(ruta: string): string {
    const limpia = normalize(ruta).replace(/^(\.\.(\/|\\|$))+/, '');
    return join(this.directorio, limpia);
  }
}
