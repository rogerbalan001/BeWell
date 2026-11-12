import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Centavos } from '../../../shared/domain/dinero';
import { NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { DatosNuevoPago, EstadoPago, Pago, PROVEEDOR_SIMULADO } from '../domain/pago';
import { PagoRepository } from '../domain/pago.repository';
import { PasarelaPagos } from './pasarela-pagos';

export type DatosCobro = DatosNuevoPago;

/** «Control» PagosService: cobro con retención, liberación, reembolso y disputas. */
@Injectable()
export class PagosService {
  private readonly logger = new Logger(PagosService.name);

  constructor(
    private readonly pagos: PagoRepository,
    private readonly pasarela: PasarelaPagos,
    private readonly reloj: Reloj,
  ) {}

  get proveedorActivo(): string {
    return this.pasarela.proveedor;
  }

  /**
   * Inicia el cobro de una cita con la pasarela activa. Idempotente por cita.
   * - Pasarela inmediata: el pago queda RETENIDO (o FALLIDO) en el acto.
   * - PayPal: el pago queda PENDIENTE_APROBACION con la URL donde el paciente lo aprueba.
   */
  async iniciarCobro(datos: DatosCobro): Promise<Pago> {
    if (!this.pasarela.requiereAprobacion) return this.retenerPago(datos);
    const clave = Pago.claveParaCita(datos.citaId);
    const existente = await this.pagos.buscarPorClaveIdempotencia(clave);
    if (existente) return existente;
    const orden = await this.pasarela.crearOrden(datos.monto, datos.moneda, datos.citaId, clave);
    const pago = Pago.iniciar(datos, { proveedor: this.pasarela.proveedor, ...orden }, this.reloj.ahora());
    await this.pagos.guardar(pago);
    return pago;
  }

  /** Autoriza y retiene el cobro de una cita con una pasarela inmediata. Idempotente por cita. */
  async retenerPago(datos: DatosCobro): Promise<Pago> {
    const clave = Pago.claveParaCita(datos.citaId);
    const existente = await this.pagos.buscarPorClaveIdempotencia(clave);
    if (existente) return existente;
    const resultado = await this.pasarela.autorizar(datos.monto, datos.moneda, datos.citaId, clave);
    const pago = Pago.registrar(datos, resultado, this.reloj.ahora(), this.pasarela.proveedor);
    await this.pagos.guardar(pago);
    return pago;
  }

  /** Datos de demostración: pago retenido sin pasar por ningún procesador (ni siquiera con PayPal activo). */
  async registrarPagoDemo(datos: DatosCobro): Promise<Pago> {
    const clave = Pago.claveParaCita(datos.citaId);
    const existente = await this.pagos.buscarPorClaveIdempotencia(clave);
    if (existente) return existente;
    const referencia = `DEMO-${datos.citaId.slice(-8).toUpperCase()}`;
    const pago = Pago.registrar(datos, { aprobado: true, referencia, mensaje: 'Pago de demostración' }, this.reloj.ahora(), PROVEEDOR_SIMULADO);
    await this.pagos.guardar(pago);
    return pago;
  }

  /**
   * El paciente volvió de PayPal (o pidió verificar): se autoriza la orden y el
   * monto queda retenido. Si aún no la aprobó, el pago sigue pendiente.
   */
  async autorizarOrden(orden: string): Promise<Pago> {
    const pago = await this.pagos.buscarPorOrdenPasarela(orden);
    if (!pago) throw new NoEncontradoError('Pago de la orden', orden);
    return this.autorizarPendiente(pago);
  }

  async autorizarPendiente(pago: Pago): Promise<Pago> {
    if (!pago.pendienteDeAprobacion || !pago.ordenPasarela) return pago;
    const pasarela = this.pasarelaDe(pago);
    if (!pasarela) return pago;
    const resultado = await pasarela.autorizarOrden(pago.ordenPasarela);
    pago.aplicarAutorizacion(resultado, this.reloj.ahora());
    if (!resultado.pendiente) await this.pagos.guardar(pago);
    return pago;
  }

  /** La cita se canceló o venció antes de que el paciente pagara: no hay nada que cobrar ni devolver. */
  async descartarPendiente(citaId: string, nota: string): Promise<Pago | null> {
    const pago = await this.pagos.buscarPorCita(citaId);
    if (!pago || !pago.pendienteDeAprobacion) return pago;
    pago.descartar(nota, this.reloj.ahora());
    await this.pagos.guardar(pago);
    return pago;
  }

  /** Pagos que esperan la aprobación del paciente desde hace más del plazo permitido. */
  async pendientesVencidos(): Promise<Pago[]> {
    const ahora = this.reloj.ahora();
    return (await this.pagos.buscarPendientesDeAprobacion()).filter((p) => p.aprobacionVencida(ahora));
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
    if (pago?.pendienteDeAprobacion) return this.descartarPendiente(citaId, nota || 'La cita se canceló antes del pago');
    if (!pago || (pago.estado !== EstadoPago.RETENIDO && pago.estado !== EstadoPago.EN_DISPUTA)) return pago;
    const pasarela = this.pasarelaDe(pago);
    if (pasarela && pago.referenciaPasarela) {
      // La cita ya quedó cancelada: un fallo de la pasarela no la revierte. Se registra para revisarlo;
      // una retención que nunca se captura vence sola y el dinero vuelve al paciente.
      try {
        if (monto > 0) await this.exigir(pasarela.reembolsar(pago.referenciaPasarela, monto, pago.moneda), 'reembolsar');
        if (monto < pago.monto) await this.exigir(pasarela.capturar(pago.referenciaPasarela, pago.monto - monto, pago.moneda), 'capturar');
      } catch (e) {
        this.logger.error(`Reembolso del pago ${pago.id} con errores en la pasarela: ${(e as Error).message}`);
        nota = `${nota} (revisar en la pasarela: ${(e as Error).message})`;
      }
    }
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
    const pasarela = this.pasarelaDe(pago);
    if (accion === 'LIBERAR') {
      if (pasarela && pago.referenciaPasarela) await this.exigir(pasarela.capturar(pago.referenciaPasarela, pago.monto, pago.moneda), 'capturar');
      pago.liberar(this.reloj.ahora(), `Disputa resuelta a favor del médico. ${nota}`);
    } else {
      if (pasarela && pago.referenciaPasarela) await this.exigir(pasarela.reembolsar(pago.referenciaPasarela, pago.monto, pago.moneda), 'reembolsar');
      pago.reembolsar(pago.monto, this.reloj.ahora(), `Disputa resuelta a favor del paciente. ${nota}`);
    }
    await this.pagos.guardar(pago);
    return pago;
  }

  obtenerPorOrden(orden: string): Promise<Pago | null> {
    return this.pagos.buscarPorOrdenPasarela(orden);
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
        const pasarela = this.pasarelaDe(pago);
        if (pasarela && pago.referenciaPasarela) await this.exigir(pasarela.capturar(pago.referenciaPasarela, pago.monto, pago.moneda), 'capturar');
        pago.liberar(ahora);
        await this.pagos.guardar(pago);
      } catch (e) {
        this.logger.error(`No se pudo liberar el pago ${pago.id}: ${(e as Error).message}`);
      }
    }
    if (pendientes.length) this.logger.log(`Pagos liberados: ${pendientes.length}`);
    return pendientes.length;
  }

  /**
   * Pasarela que procesó el pago. Los pagos de demostración (o de otra pasarela
   * que ya no está activa) solo cambian de estado aquí, sin llamadas externas.
   */
  private pasarelaDe(pago: Pago): PasarelaPagos | null {
    return (pago.proveedor ?? PROVEEDOR_SIMULADO) === this.pasarela.proveedor ? this.pasarela : null;
  }

  private async exigir(operacion: Promise<{ aprobado: boolean; mensaje?: string }>, accion: string): Promise<void> {
    const r = await operacion;
    if (!r.aprobado) throw new Error(`La pasarela no pudo ${accion} el pago: ${r.mensaje ?? 'sin detalle'}`);
  }
}
