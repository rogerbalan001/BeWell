import { createHash } from 'crypto';

/**
 * Obtiene una llave de 32 bytes a partir de una variable de entorno.
 * Si el valor es base64 de exactamente 32 bytes se usa tal cual; si no
 * (p. ej. un secreto generado por el hosting con otro formato), se deriva
 * con SHA-256 para obtener siempre una llave AES-256 válida.
 */
export function llaveDe32Bytes(valor: string | undefined, nombre: string): Buffer {
  if (!valor || valor.startsWith('REEMPLAZAR')) {
    throw new Error(`Falta la variable de entorno ${nombre} (ejecuta "npm run configurar")`);
  }
  const decodificada = Buffer.from(valor, 'base64');
  if (decodificada.length === 32 && decodificada.toString('base64') === valor.trim()) return decodificada;
  return createHash('sha256').update(valor).digest();
}
