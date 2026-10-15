import { Centavos } from '../../../shared/domain/dinero';

export interface ResultadoPasarela {
  aprobado: boolean;
  referencia?: string;
  mensaje?: string;
}

/**
 * «Boundary» PasarelaPagosAdapter (puerto). Encapsula al procesador de pagos
 * para poder conectar uno local (Stripe no opera en Venezuela) sin tocar el
 * dominio. Los datos de tarjeta nunca pasan por nuestros servidores.
 */
export abstract class PasarelaPagos {
  abstract autorizar(monto: Centavos, moneda: string, referenciaInterna: string, claveIdempotencia: string): Promise<ResultadoPasarela>;
  abstract capturar(referencia: string, monto: Centavos): Promise<ResultadoPasarela>;
  abstract reembolsar(referencia: string, monto: Centavos): Promise<ResultadoPasarela>;
}
