import { Injectable } from '@nestjs/common';
import { createHash, verify } from 'crypto';
import { Kms } from './kms';

/**
 * JSON Canonicalization Scheme (RFC 8785): claves ordenadas por unidades
 * UTF-16 y números serializados según ECMAScript.
 */
export function canonicalizar(valor: unknown): string {
  if (valor === null || typeof valor !== 'object') return JSON.stringify(valor);
  if (Array.isArray(valor)) return `[${valor.map((v) => canonicalizar(v === undefined ? null : v)).join(',')}]`;
  const obj = valor as Record<string, unknown>;
  return `{${Object.keys(obj)
    .filter((k) => obj[k] !== undefined)
    .sort()
    .map((k) => `${JSON.stringify(k)}:${canonicalizar(obj[k])}`)
    .join(',')}}`;
}

export interface Firma {
  hash: string;
  firma: string;
}

/** «Control» FirmaDigitalService: canonicaliza, calcula el hash y firma vía KMS. */
@Injectable()
export class FirmaDigitalService {
  constructor(private readonly kms: Kms) {}

  canonicalizar(contenido: Record<string, unknown>): string {
    return canonicalizar(contenido);
  }

  async firmar(llaveId: string, contenido: Record<string, unknown>): Promise<Firma> {
    const canonico = Buffer.from(this.canonicalizar(contenido), 'utf8');
    return {
      hash: createHash('sha256').update(canonico).digest('hex'),
      firma: await this.kms.firmar(llaveId, canonico),
    };
  }

  async verificar(contenido: Record<string, unknown>, firma: string, llaveId: string): Promise<{ firmaValida: boolean; hash: string }> {
    const canonico = Buffer.from(this.canonicalizar(contenido), 'utf8');
    const hash = createHash('sha256').update(canonico).digest('hex');
    try {
      const publica = await this.kms.obtenerLlavePublica(llaveId);
      return { firmaValida: verify('sha256', canonico, publica, Buffer.from(firma, 'base64')), hash };
    } catch {
      return { firmaValida: false, hash };
    }
  }
}
