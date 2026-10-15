import { Centavos } from '../../../shared/domain/dinero';
import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { sumarHoras } from '../../../shared/domain/reloj';

export enum EstadoPago {
  RETENIDO = 'RETENIDO',
  EN_DISPUTA = 'EN_DISPUTA',
  LIBERADO = 'LIBERADO',
  REEMBOLSADO_PARCIAL = 'REEMBOLSADO_PARCIAL',
  REEMBOLSADO = 'REEMBOLSADO',
  FALLIDO = 'FALLIDO',
}

/** Horas que el pago permanece retenido tras marcar la cita como atendida (HU pagos). */
export const HORAS_RETENCION_TRAS_CONSULTA = 24;

export interface MovimientoPago {
  estado: EstadoPago;
  fecha: Date;
  nota?: string;
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
  referenciaPasarela?: string;
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
  referenciaPasarela?: string;
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

  static registrar(
    datos: { citaId: string; pacienteId: string; medicoId: string; monto: Centavos; moneda: string },
    resultado: { aprobado: boolean; referencia?: string; mensaje?: string },
    ahora: Date,
  ): Pago {
    asegurar(datos.monto > 0, 'El monto del pago debe ser mayor que cero');
    const estado = resultado.aprobado ? EstadoPago.RETENIDO : EstadoPago.FALLIDO;
    return new Pago({
      id: generarId(),
      ...datos,
      modalidad: 'RETENCION',
      estado,
      referenciaPasarela: resultado.referencia,
      claveIdempotencia: Pago.claveParaCita(datos.citaId),
      montoReembolsado: 0,
      historial: [{ estado, fecha: ahora, nota: resultado.mensaje }],
      creadoEn: ahora,
      actualizadoEn: ahora,
    });
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
