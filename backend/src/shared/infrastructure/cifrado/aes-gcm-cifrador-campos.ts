import { createCipheriv, createDecipheriv, createHmac, randomBytes } from 'crypto';
import { CifradorCampos } from '../../application/cifrador-campos';

const PREFIJO = 'v1:';

/**
 * Cifrado explícito a nivel de campo con AES-256-GCM (autenticado).
 * Formato: "v1:" + base64(iv[12] | tag[16] | texto cifrado).
 */
export class AesGcmCifradorCampos extends CifradorCampos {
  private readonly llaveHuella: Buffer;

  constructor(private readonly llave: Buffer) {
    super();
    if (llave.length !== 32) {
      throw new Error('FIELD_ENCRYPTION_KEY debe ser de 32 bytes en base64');
    }
    this.llaveHuella = createHmac('sha256', llave).update('bewell:huella').digest();
  }

  cifrar(texto: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.llave, iv);
    const cifrado = Buffer.concat([cipher.update(texto, 'utf8'), cipher.final()]);
    return PREFIJO + Buffer.concat([iv, cipher.getAuthTag(), cifrado]).toString('base64');
  }

  descifrar(valor: string): string {
    if (!valor.startsWith(PREFIJO)) return valor; // datos heredados sin cifrar
    const datos = Buffer.from(valor.slice(PREFIJO.length), 'base64');
    const decipher = createDecipheriv('aes-256-gcm', this.llave, datos.subarray(0, 12));
    decipher.setAuthTag(datos.subarray(12, 28));
    return Buffer.concat([decipher.update(datos.subarray(28)), decipher.final()]).toString('utf8');
  }

  huella(texto: string): string {
    return createHmac('sha256', this.llaveHuella).update(texto.trim().toUpperCase()).digest('hex');
  }
}
