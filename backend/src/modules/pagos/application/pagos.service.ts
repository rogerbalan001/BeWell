import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Centavos } from '../../../shared/domain/dinero';
import { NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { EstadoPago, Pago } from '../domain/pago';
import { PagoRepository } from '../domain/pago.repository';
import { PasarelaPagos } from './pasarela-pagos';

export interface DatosCobro {
  citaId: string;
  pacienteId: string;
  medicoId: string;
  monto: Centavos;
  moneda: string;
}

/** «Control» PagosService: retención, liberación, reembolso y disputas. */
@Injectable()
export class PagosService {
  private readonly logger = new Logger(PagosService.name);

  constructor(
    private readonly pagos: PagoRepository,
    private readonly pasarela: PasarelaPagos,
    private readonly reloj: Reloj,
  ) {}

  /** Autoriza y retiene el cobro de una cita. Idempotente por cita. */
  async retenerPago(datos: DatosCobro): Promise<Pago> {
    const clave = Pago.claveParaCita(datos.citaId);
    const existente = await this.pagos.buscarPorClaveIdempotencia(clave);
    if (existente) return existente;
    const resultado = await this.pasarela.autorizar(datos.monto, datos.moneda, datos.citaId, clave);
    const pago = Pago.registrar(datos, resultado, this.reloj.ahora());
    await this.pagos.guardar(pago);
    return pago;
  }

  async programarLiberacion(citaId: string): Promise<Pago | null> {
    const pago = await this.pagos.buscarPorCita(citaId);
    if (!pago || pago.estado !== EstadoPago.RETENIDO) return pago;
    pago.programarLiberacion(this.reloj.ahora());
    await this.pagos.guardar(pago);
    return pago;
  }

  async reembolsar(citaId: string, monto: Centavos, nota: string): Promise<Pago | null> {
    const pago = await this.pagos.buscarPorCita(citaId);
    if (!pago || (pago.estado !== EstadoPago.RETENIDO && pago.estado !== EstadoPago.EN_DISPUTA)) return pago;
    if (monto > 0 && pago.referenciaPasarela) await this.pasarela.reembolsar(pago.referenciaPasarela, monto);
    if (monto < pago.monto && pago.referenciaPasarela) await this.pasarela.capturar(pago.referenciaPasarela, pago.monto - monto);
    pago.reembolsar(monto, this.reloj.ahora(), nota);
    await this.pagos.guardar(pago);
    return pago;
  }

  async abrirDisputa(citaId: string, motivo: string): Promise<Pago> {
    const pago = await this.pagos.buscarPorCita(citaId);
    if (!pago) throw new NoEncontradoError('Pago de la cita', citaId);
    pago.abrirDisputa(motivo, this.reloj.ahora());
    await this.pagos.guardar(pago);
    return pago;
  }

  async resolverDisputa(pagoId: string, accion: 'LIBERAR' | 'REEMBOLSAR', nota: string): Promise<Pago> {
    const pago = await this.pagos.buscarPorId(pagoId);
    if (!pago) throw new NoEncontradoError('Pago', pagoId);
    if (accion === 'LIBERAR') {
      if (pago.referenciaPasarela) await this.pasarela.capturar(pago.referenciaPasarela, pago.monto);
      pago.liberar(this.reloj.ahora(), `Disputa resuelta a favor del médico. ${nota}`);
    } else {
      if (pago.referenciaPasarela) await this.pasarela.reembolsar(pago.referenciaPasarela, pago.monto);
      pago.reembolsar(pago.monto, this.reloj.ahora(), `Disputa resuelta a favor del paciente. ${nota}`);
    }
    await this.pagos.guardar(pago);
    return pago;
  }

  obtenerPorCita(citaId: string): Promise<Pago | null> {
    return this.pagos.buscarPorCita(citaId);
  }

  obtenerPorCitas(citaIds: string[]): Promise<Pago[]> {
    return citaIds.length ? this.pagos.buscarPorCitas(citaIds) : Promise.resolve([]);
  }

  listarDisputas(): Promise<Pago[]> {
    return this.pagos.buscarEnDisputa();
  }

  /** Worker programado: libera al médico los pagos cuya retención de 24 h venció. */
  @Cron(CronExpression.EVERY_5_MINUTES)
  async liberarPagosVencidos(): Promise<number> {
    const ahora = this.reloj.ahora();
    const pendientes = await this.pagos.buscarListosParaLiberar(ahora);
    for (const pago of pendientes) {
      try {
        if (pago.referenciaPasarela) await this.pasarela.capturar(pago.referenciaPasarela, pago.monto);
        pago.liberar(ahora);
        await this.pagos.guardar(pago);
      } catch (e) {
        this.logger.error(`No se pudo liberar el pago ${pago.id}: ${(e as Error).message}`);
      }
    }
    if (pendientes.length) this.logger.log(`Pagos liberados: ${pendientes.length}`);
    return pendientes.length;
  }
}
