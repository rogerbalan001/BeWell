import { Pago } from './pago';

/** «Repository» de pagos (colección `pagos`). */
export abstract class PagoRepository {
  abstract guardar(pago: Pago): Promise<void>;
  abstract buscarPorId(id: string): Promise<Pago | null>;
  abstract buscarPorCita(citaId: string): Promise<Pago | null>;
  abstract buscarPorCitas(citaIds: string[]): Promise<Pago[]>;
  abstract buscarPorClaveIdempotencia(clave: string): Promise<Pago | null>;
  abstract buscarListosParaLiberar(ahora: Date): Promise<Pago[]>;
  abstract buscarEnDisputa(): Promise<Pago[]>;
}
