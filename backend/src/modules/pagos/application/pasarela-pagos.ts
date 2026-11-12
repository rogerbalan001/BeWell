import { Centavos } from '../../../shared/domain/dinero';
import { PROVEEDOR_SIMULADO } from '../domain/pago';

export interface ResultadoPasarela {
  aprobado: boolean;
  referencia?: string;
  mensaje?: string;
  /** El pagador todavía no aprueba la orden (p. ej. no terminó en PayPal): no es un rechazo. */
  pendiente?: boolean;
}

/** Orden creada en una pasarela que requiere que el pagador la apruebe en su sitio (PayPal). */
export interface OrdenPasarela {
  orden: string;
  urlAprobacion: string;
}

/**
 * «Boundary» PasarelaPagosAdapter (puerto). Encapsula al procesador de pagos
 * para poder cambiarlo sin tocar el dominio. Los datos de tarjeta o de la
 * cuenta del pagador nunca pasan por nuestros servidores.
 *
 * Dos estilos de pasarela:
 * - inmediata (`requiereAprobacion = false`): `autorizar` retiene el monto en el acto;
 * - con aprobación del pagador (PayPal): `crearOrden` devuelve la URL donde el
 *   paciente aprueba el pago y, al volver, `autorizarOrden` retiene el monto.
 * En ambos casos el dinero queda retenido hasta `capturar` (se libera al médico)
 * o `reembolsar` (vuelve al paciente).
 */
export abstract class PasarelaPagos {
  /** Nombre guardado en cada pago para saber qué pasarela lo procesó. */
  get proveedor(): string {
    return PROVEEDOR_SIMULADO;
  }

  get requiereAprobacion(): boolean {
    return false;
  }

  abstract autorizar(monto: Centavos, moneda: string, referenciaInterna: string, claveIdempotencia: string): Promise<ResultadoPasarela>;
  abstract capturar(referencia: string, monto: Centavos, moneda?: string): Promise<ResultadoPasarela>;
  abstract reembolsar(referencia: string, monto: Centavos, moneda?: string): Promise<ResultadoPasarela>;

  crearOrden(_monto: Centavos, _moneda: string, _referenciaInterna: string, _claveIdempotencia: string): Promise<OrdenPasarela> {
    return Promise.reject(new Error(`La pasarela ${this.proveedor} no usa órdenes con aprobación`));
  }

  autorizarOrden(_orden: string): Promise<ResultadoPasarela> {
    return Promise.reject(new Error(`La pasarela ${this.proveedor} no usa órdenes con aprobación`));
  }
}
