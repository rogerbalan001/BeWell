import { Centavos } from '../../../shared/domain/dinero';
import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { sumarHoras } from '../../../shared/domain/reloj';

export enum EstadoPago {
  /** Orden creada en la pasarela (PayPal); falta que el paciente la apruebe. */
  PENDIENTE_APROBACION = 'PENDIENTE_APROBACION',
  RETENIDO = 'RETENIDO',
  EN_DISPUTA = 'EN_DISPUTA',
  LIBERADO = 'LIBERADO',
  REEMBOLSADO_PARCIAL = 'REEMBOLSADO_PARCIAL',
  REEMBOLSADO = 'REEMBOLSADO',
  FALLIDO = 'FALLIDO',
}

/** Horas que el pago permanece retenido tras marcar la cita como atendida (HU pagos). */
export const HORAS_RETENCION_TRAS_CONSULTA = 24;

/** Proveedor de la pasarela simulada y de los pagos de demostración: nunca llama a un procesador externo. */
export const PROVEEDOR_SIMULADO = 'SIMULADA';

/** Minutos que se guarda la franja mientras el paciente aprueba el pago en PayPal. */
export const MINUTOS_PARA_APROBAR_PAGO = 30;

export interface MovimientoPago {
  estado: EstadoPago;
  fecha: Date;
  nota?: string;
}

export interface DatosNuevoPago {
  citaId: string;
  pacienteId: string;
  medicoId: string;
  monto: Centavos;
  moneda: string;
}

export interface PropsPago {
  id: string;
  citaId: string;
  pacienteId: string;
  medicoId: string;
  monto: Centavos;
  moneda: string;
  /** RETENCION (pago diferido: se cobra al reservar y se libera tras la consulta). */
  modalidad: string;
  estado: EstadoPago;
  /** Pasarela que procesó el pago (SIMULADA, PAYPAL). */
  proveedor: string;
  /** Autorización (retención) en la pasarela: se captura o se anula después. */
  referenciaPasarela?: string;
  /** Orden de la pasarela que el paciente debe aprobar (PayPal). */
  ordenPasarela?: string;
  /** Página de la pasarela donde el paciente aprueba el pago. */
  urlAprobacion?: string;
  claveIdempotencia: string;
  liberarDespuesDe?: Date;
  montoReembolsado: Centavos;
  motivoDisputa?: string;
  historial: MovimientoPago[];
  creadoEn: Date;
  actualizadoEn: Date;
}

/**
 * «Entity» Pago con retención: el cobro se autoriza al reservar y el dinero
 * se libera al médico 24 h después de la consulta, salvo disputa del paciente.
 */
export class Pago implements PropsPago {
  id: string;
  citaId: string;
  pacienteId: string;
  medicoId: string;
  monto: Centavos;
  moneda: string;
  modalidad: string;
  estado: EstadoPago;
  proveedor: string;
  referenciaPasarela?: string;
  ordenPasarela?: string;
  urlAprobacion?: string;
  claveIdempotencia: string;
  liberarDespuesDe?: Date;
  montoReembolsado: Centavos;
  motivoDisputa?: string;
  historial: MovimientoPago[];
  creadoEn: Date;
  actualizadoEn: Date;

  constructor(props: PropsPago) {
    Object.assign(this, props);
  }

  /** Pasarela inmediata: el monto queda retenido (o rechazado) en el acto. */
  static registrar(
    datos: DatosNuevoPago,
    resultado: { aprobado: boolean; referencia?: string; mensaje?: string },
    ahora: Date,
    proveedor = PROVEEDOR_SIMULADO,
  ): Pago {
    asegurar(datos.monto > 0, 'El monto del pago debe ser mayor que cero');
    const estado = resultado.aprobado ? EstadoPago.RETENIDO : EstadoPago.FALLIDO;
    return new Pago({
      id: generarId(),
      ...datos,
      modalidad: 'RETENCION',
      estado,
      proveedor,
      referenciaPasarela: resultado.referencia,
      claveIdempotencia: Pago.claveParaCita(datos.citaId),
      montoReembolsado: 0,
      historial: [{ estado, fecha: ahora, nota: resultado.mensaje }],
      creadoEn: ahora,
      actualizadoEn: ahora,
    });
  }

  /** Pasarela con aprobación (PayPal): el pago espera a que el paciente lo apruebe. */
  static iniciar(datos: DatosNuevoPago, orden: { proveedor: string; orden: string; urlAprobacion: string }, ahora: Date): Pago {
    asegurar(datos.monto > 0, 'El monto del pago debe ser mayor que cero');
    asegurar(orden.orden && orden.urlAprobacion, 'La pasarela no devolvió la orden de pago');
    return new Pago({
      id: generarId(),
      ...datos,
      modalidad: 'RETENCION',
      estado: EstadoPago.PENDIENTE_APROBACION,
      proveedor: orden.proveedor,
      ordenPasarela: orden.orden,
      urlAprobacion: orden.urlAprobacion,
      claveIdempotencia: Pago.claveParaCita(datos.citaId),
      montoReembolsado: 0,
      historial: [{ estado: EstadoPago.PENDIENTE_APROBACION, fecha: ahora, nota: `Orden ${orden.orden} creada; falta la aprobación del paciente` }],
      creadoEn: ahora,
      actualizadoEn: ahora,
    });
  }

  get pendienteDeAprobacion(): boolean {
    return this.estado === EstadoPago.PENDIENTE_APROBACION;
  }

  /** La franja deja de guardarse si el paciente no aprueba el pago a tiempo. */
  aprobacionVencida(ahora: Date): boolean {
    return this.pendienteDeAprobacion && ahora.getTime() - this.creadoEn.getTime() >= MINUTOS_PARA_APROBAR_PAGO * 60_000;
  }

  /** Resultado de autorizar la orden ya aprobada: queda RETENIDO o FALLIDO. Si sigue pendiente no cambia. */
  aplicarAutorizacion(resultado: { aprobado: boolean; referencia?: string; mensaje?: string; pendiente?: boolean }, ahora: Date): void {
    this.exigirEstado(EstadoPago.PENDIENTE_APROBACION);
    if (resultado.pendiente) return;
    if (resultado.aprobado) {
      asegurar(resultado.referencia, 'La pasarela no devolvió la autorización del pago');
      this.referenciaPasarela = resultado.referencia;
      this.urlAprobacion = undefined;
      this.cambiarEstado(EstadoPago.RETENIDO, ahora, resultado.mensaje ?? 'Pago aprobado y retenido');
    } else {
      this.urlAprobacion = undefined;
      this.cambiarEstado(EstadoPago.FALLIDO, ahora, resultado.mensaje ?? 'La pasarela rechazó el pago');
    }
  }

  /** El paciente no completó el pago (venció el plazo o se canceló la cita): no se cobró nada. */
  descartar(nota: string, ahora: Date): void {
    this.exigirEstado(EstadoPago.PENDIENTE_APROBACION);
    this.urlAprobacion = undefined;
    this.cambiarEstado(EstadoPago.FALLIDO, ahora, nota);
  }

  /** Una cita solo puede cobrarse una vez aunque la app reintente la solicitud. */
  static claveParaCita(citaId: string): string {
    return `cita:${citaId}`;
  }

  get montoParaMedico(): Centavos {
    return this.monto - this.montoReembolsado;
  }

  /** Se invoca al marcar la cita como atendida (o inasistencia del paciente). */
  programarLiberacion(desde: Date): void {
    this.exigirEstado(EstadoPago.RETENIDO);
    this.liberarDespuesDe = sumarHoras(desde, HORAS_RETENCION_TRAS_CONSULTA);
    this.registrarMovimiento(EstadoPago.RETENIDO, desde, `Liberación programada para ${this.liberarDespuesDe.toISOString()}`);
  }

  puedeLiberarse(ahora: Date): boolean {
    return this.estado === EstadoPago.RETENIDO && !!this.liberarDespuesDe && this.liberarDespuesDe <= ahora;
  }

  liberar(ahora: Date, nota = 'Liberado al médico'): void {
    asegurar(this.estado === EstadoPago.RETENIDO || this.estado === EstadoPago.EN_DISPUTA, 'Solo se libera un pago retenido');
    this.cambiarEstado(EstadoPago.LIBERADO, ahora, nota);
  }

  /** El paciente reporta un problema dentro de las 24 h: el pago queda retenido hasta revisión. */
  abrirDisputa(motivo: string, ahora: Date): void {
    asegurar(motivo?.trim(), 'Describe el problema');
    this.exigirEstado(EstadoPago.RETENIDO);
    asegurar(!!this.liberarDespuesDe, 'Solo se puede reportar un problema después de la consulta');
    asegurar(ahora < this.liberarDespuesDe!, 'El plazo de 24 horas para reportar un problema ya venció');
    this.motivoDisputa = motivo.trim();
    this.cambiarEstado(EstadoPago.EN_DISPUTA, ahora, motivo);
  }

  /** Reembolso por cancelación (antes de la consulta) o por resolución de una disputa. */
  reembolsar(monto: Centavos, ahora: Date, nota?: string): void {
    asegurar(this.estado === EstadoPago.RETENIDO || this.estado === EstadoPago.EN_DISPUTA, 'El pago ya no puede reembolsarse');
    asegurar(monto >= 0 && monto <= this.monto, 'Monto de reembolso inválido');
    this.montoReembolsado = monto;
    const estado =
      monto === this.monto ? EstadoPago.REEMBOLSADO : monto === 0 ? EstadoPago.LIBERADO : EstadoPago.REEMBOLSADO_PARCIAL;
    this.cambiarEstado(estado, ahora, nota);
  }

  private exigirEstado(estado: EstadoPago): void {
    if (this.estado !== estado) throw new ReglaNegocioError(`El pago está ${this.estado}, se esperaba ${estado}`);
  }

  private cambiarEstado(estado: EstadoPago, ahora: Date, nota?: string): void {
    this.estado = estado;
    this.registrarMovimiento(estado, ahora, nota);
  }

  private registrarMovimiento(estado: EstadoPago, ahora: Date, nota?: string): void {
    this.historial = [...this.historial, { estado, fecha: ahora, nota }];
    this.actualizadoEn = ahora;
  }
}
