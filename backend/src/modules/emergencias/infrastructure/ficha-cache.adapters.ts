import { Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { FichaCacheada, FichaEmergenciaCache } from '../application/ficha-emergencia.cache';

/** Caché en memoria del proceso (desarrollo / una sola réplica). */
export class FichaCacheMemoria extends FichaEmergenciaCache {
  private readonly entradas = new Map<string, { valor: FichaCacheada; expira: number }>();

  async obtener(hash: string): Promise<FichaCacheada | null> {
    const e = this.entradas.get(hash);
    if (!e) return null;
    if (Date.now() > e.expira) {
      this.entradas.delete(hash);
      return null;
    }
    return e.valor;
  }

  async guardar(hash: string, valor: FichaCacheada, ttl: number): Promise<void> {
    this.entradas.set(hash, { valor, expira: Date.now() + ttl * 1000 });
  }

  async invalidar(hash: string): Promise<void> {
    this.entradas.delete(hash);
  }
}

/** Caché en Redis compartida por todas las réplicas de la API (decisión D5). */
export class FichaCacheRedis extends FichaEmergenciaCache {
  private readonly logger = new Logger(FichaCacheRedis.name);
  constructor(private readonly redis: Redis) {
    super();
  }

  private clave(hash: string): string {
    return `ficha:${hash}`;
  }

  async obtener(hash: string): Promise<FichaCacheada | null> {
    try {
      const raw = await this.redis.get(this.clave(hash));
      return raw ? (JSON.parse(raw) as FichaCacheada) : null;
    } catch (e) {
      this.logger.warn(`Redis no disponible, se lee de MongoDB: ${(e as Error).message}`);
      return null;
    }
  }

  async guardar(hash: string, valor: FichaCacheada, ttl: number): Promise<void> {
    await this.redis.set(this.clave(hash), JSON.stringify(valor), 'EX', ttl).catch(() => undefined);
  }

  async invalidar(hash: string): Promise<void> {
    await this.redis.del(this.clave(hash)).catch(() => undefined);
  }
}
