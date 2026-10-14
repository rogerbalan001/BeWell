import { randomBytes } from 'crypto';

/**
 * Genera un identificador de 24 caracteres hexadecimales compatible con
 * ObjectId de MongoDB (4 bytes de tiempo + 8 aleatorios), sin depender del
 * driver. Permite que el dominio cree entidades con identidad antes de
 * persistirlas.
 */
export function generarId(): string {
  const segundos = Math.floor(Date.now() / 1000).toString(16).padStart(8, '0');
  return segundos + randomBytes(8).toString('hex');
}

export function esIdValido(id: unknown): id is string {
  return typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id);
}
