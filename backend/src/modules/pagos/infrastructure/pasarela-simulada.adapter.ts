import { Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Centavos } from '../../../shared/domain/dinero';
import { PasarelaPagos, ResultadoPasarela } from '../application/pasarela-pagos';

/**
 * Adapter de pasarela SIMULADA para el MVP (alcance Sprint 1: "registro del
 * monto y estados del pago"). Aprueba todas las operaciones y responde de
 * forma idempotente. Se reemplaza por el procesador real en sprints posteriores.
 */
@Injectable()
export class PasarelaSimuladaAdapter extends PasarelaPagos {
  private readonly logger = new Logger('PasarelaSimulada');
  private readonly autorizaciones = new Map<string, string>();

  async autorizar(monto: Centavos, moneda: string, referenciaInterna: string, claveIdempotencia: string): Promise<ResultadoPasarela> {
    const previa = this.autorizaciones.get(claveIdempotencia);
    if (previa) return { aprobado: true, referencia: previa, mensaje: 'Autorización existente (idempotente)' };
    const referencia = `SIM-${randomUUID().slice(0, 8).toUpperCase()}`;
    this.autorizaciones.set(claveIdempotencia, referencia);
    this.logger.log(`Retención ${referencia}: ${(monto / 100).toFixed(2)} ${moneda} (cita ${referenciaInterna})`);
    return { aprobado: true, referencia, mensaje: 'Pago autorizado y retenido (pasarela simulada)' };
  }

  async capturar(referencia: string, monto: Centavos): Promise<ResultadoPasarela> {
    this.logger.log(`Captura ${referencia}: ${(monto / 100).toFixed(2)}`);
    return { aprobado: true, referencia };
  }

  async reembolsar(referencia: string, monto: Centavos): Promise<ResultadoPasarela> {
    this.logger.log(`Reembolso ${referencia}: ${(monto / 100).toFixed(2)}`);
    return { aprobado: true, referencia };
  }
}
