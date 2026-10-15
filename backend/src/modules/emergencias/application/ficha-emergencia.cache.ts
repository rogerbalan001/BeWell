import { PropsFicha } from '../domain/ficha-emergencia';

/** Copia precalculada que se guarda en caché (cache-aside) para responder en < 50 ms. */
export interface FichaCacheada {
  ficha: PropsFicha;
  paciente: { nombreCompleto: string; edad: number; sexo: string };
  titularUsuarioId: string;
}

/** «Repository» FichaEmergenciaCache (Redis en producción, memoria en desarrollo). */
export abstract class FichaEmergenciaCache {
  abstract obtener(tokenHash: string): Promise<FichaCacheada | null>;
  abstract guardar(tokenHash: string, valor: FichaCacheada, ttlSegundos: number): Promise<void>;
  abstract invalidar(tokenHash: string): Promise<void>;
}
