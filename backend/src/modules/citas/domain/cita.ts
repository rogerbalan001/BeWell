import { Centavos } from '../../../shared/domain/dinero';
import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { horasEntre, sumarHoras } from '../../../shared/domain/reloj';
import { Modalidad } from '../../medicos/domain/medico';
import { PoliticaCancelacion } from '../../medicos/domain/politica-cancelacion';

export enum EstadoCita {
  /** Propuesta de seguimiento esperando que la otra parte acepte (máx. 48 h). */
  PENDIENTE_ACEPTACION = 'PENDIENTE_ACEPTACION',
  PENDIENTE_PAGO = 'PENDIENTE_PAGO',
  CONFIRMADA = 'CONFIRMADA',
  ATENDIDA = 'ATENDIDA',
  CANCELADA = 'CANCELADA',
  NO_ASISTIO = 'NO_ASISTIO',
}

/** Estados que ocupan la franja del médico (índice único parcial anti doble reserva). */
export const ESTADOS_ACTIVOS = [EstadoCita.PENDIENTE_ACEPTACION, EstadoCita.PENDIENTE_PAGO, EstadoCita.CONFIRMADA];

export type Parte = 'PACIENTE' | 'MEDICO';
export type Cancelador = Parte | 'SISTEMA';

export const HORAS_EXPIRACION_PROPUESTA = 48;
/** Margen para marcar la cita como atendida antes de la hora de inicio. */
const MINUTOS_TOLERANCIA_INICIO = 15;

export interface PropsCita {
  id: string;
  pacienteId: string;
  medicoId: string;
  agendadaPorUsuarioId: string;
  inicio: Date;
  fin: Date;
  modalidad: Modalidad;
  motivo: string;
  estado: EstadoCita;
  monto: Centavos;
  moneda: string;
  /** Copia de la política vigente al agendar (decisión D7). */
  politicaAplicada: PoliticaCancelacion;
  citaOrigenId?: string;
  referenciaId?: string;
  propuestaPor?: Parte;
  propuestaExpiraEn?: Date;
  canceladaPor?: Cancelador;
  motivoCancelacion?: string;
  canceladaEn?: Date;
  atendidaEn?: Date;
  creadaEn: Date;
}

interface DatosNuevaCita {
  pacienteId: string;
  medicoId: string;
  agendadaPorUsuarioId: string;
  inicio: Date;
  fin: Date;
  modalidad: Modalidad;
  motivo: string;
  monto: Centavos;
  moneda: string;
  politica: PoliticaCancelacion;
}

/** «Entity» Cita con su máquina de estados y el cálculo del reembolso. */
export class Cita implements PropsCita {
  id: string;
  pacienteId: string;
  medicoId: string;
  agendadaPorUsuarioId: string;
  inicio: Date;
  fin: Date;
  modalidad: Modalidad;
  motivo: string;
  estado: EstadoCita;
  monto: Centavos;
  moneda: string;
  politicaAplicada: PoliticaCancelacion;
  citaOrigenId?: string;
  referenciaId?: string;
  propuestaPor?: Parte;
  propuestaExpiraEn?: Date;
  canceladaPor?: Cancelador;
  motivoCancelacion?: string;
  canceladaEn?: Date;
  atendidaEn?: Date;
  creadaEn: Date;

  constructor(props: PropsCita) {
    Object.assign(this, props);
  }

  /** Agendamiento directo por el paciente: queda pendiente de pago. */
  static agendar(datos: DatosNuevaCita, ahora: Date): Cita {
    Cita.validar(datos, ahora);
    return new Cita({
      id: generarId(),
      ...Cita.base(datos),
      estado: EstadoCita.PENDIENTE_PAGO,
      creadaEn: ahora,
    });
  }

  /** Cita de seguimiento propuesta por una parte; requiere aceptación de la otra. */
  static proponer(
    datos: DatosNuevaCita & { propuestaPor: Parte; citaOrigenId?: string; referenciaId?: string },
    ahora: Date,
  ): Cita {
    Cita.validar(datos, ahora);
    return new Cita({
      id: generarId(),
      ...Cita.base(datos),
      estado: EstadoCita.PENDIENTE_ACEPTACION,
      propuestaPor: datos.propuestaPor,
      propuestaExpiraEn: sumarHoras(ahora, HORAS_EXPIRACION_PROPUESTA),
      citaOrigenId: datos.citaOrigenId,
      referenciaId: datos.referenciaId,
      creadaEn: ahora,
    });
  }

  get ocupaFranja(): boolean {
    return ESTADOS_ACTIVOS.includes(this.estado);
  }

  confirmarPago(): void {
    this.exigir(EstadoCita.PENDIENTE_PAGO);
    this.estado = EstadoCita.CONFIRMADA;
  }

  aceptarPropuesta(parte: Parte, ahora: Date): void {
    this.exigir(EstadoCita.PENDIENTE_ACEPTACION);
    if (this.propuestaPor === parte) throw new ReglaNegocioError('La propuesta debe aceptarla la otra parte');
    if (this.propuestaVencida(ahora)) throw new ReglaNegocioError('La propuesta venció (48 h sin respuesta)');
    this.estado = EstadoCita.PENDIENTE_PAGO;
  }

  rechazarPropuesta(parte: Parte, ahora: Date): void {
    this.exigir(EstadoCita.PENDIENTE_ACEPTACION);
    this.marcarCancelada(parte, parte === this.propuestaPor ? 'Propuesta retirada' : 'Propuesta rechazada', ahora);
  }

  propuestaVencida(ahora: Date): boolean {
    return this.estado === EstadoCita.PENDIENTE_ACEPTACION && !!this.propuestaExpiraEn && ahora >= this.propuestaExpiraEn;
  }

  /** Devuelve true si la propuesta se canceló por falta de respuesta. */
  expirarPropuesta(ahora: Date): boolean {
    if (!this.propuestaVencida(ahora)) return false;
    this.marcarCancelada('SISTEMA', 'Propuesta sin respuesta en 48 horas', ahora);
    return true;
  }

  /**
   * Cancela la cita y devuelve el monto a reembolsar. Si cancela el médico se
   * reembolsa todo; si cancela el paciente se aplica la política copiada.
   */
  cancelar(por: Cancelador, motivo: string, ahora: Date): Centavos {
    if (this.estado === EstadoCita.PENDIENTE_ACEPTACION) {
      this.rechazarPropuesta(por === 'SISTEMA' ? 'MEDICO' : por, ahora);
      return 0;
    }
    asegurar(
      this.estado === EstadoCita.PENDIENTE_PAGO || this.estado === EstadoCita.CONFIRMADA,
      `No se puede cancelar una cita ${this.estado}`,
    );
    asegurar(ahora < this.inicio, 'La cita ya comenzó; no puede cancelarse');
    const pagada = this.estado === EstadoCita.CONFIRMADA;
    this.marcarCancelada(por, motivo, ahora);
    if (!pagada) return 0;
    if (por !== 'PACIENTE') return this.monto;
    return this.politicaAplicada.calcularReembolso(this.monto, horasEntre(ahora, this.inicio));
  }

  /** Simula el reembolso sin cambiar el estado (para mostrarlo antes de confirmar). */
  simularReembolso(ahora: Date): Centavos {
    if (this.estado !== EstadoCita.CONFIRMADA) return 0;
    return this.politicaAplicada.calcularReembolso(this.monto, horasEntre(ahora, this.inicio));
  }

  marcarAtendida(medicoId: string, ahora: Date): void {
    asegurar(this.medicoId === medicoId, 'Solo el médico de la cita puede marcarla como atendida');
    this.exigir(EstadoCita.CONFIRMADA);
    asegurar(
      ahora.getTime() >= this.inicio.getTime() - MINUTOS_TOLERANCIA_INICIO * 60_000,
      'No puedes marcar como atendida una cita que aún no comienza',
    );
    this.estado = EstadoCita.ATENDIDA;
    this.atendidaEn = ahora;
  }

  marcarNoAsistio(medicoId: string, ahora: Date): void {
    asegurar(this.medicoId === medicoId, 'Solo el médico de la cita puede registrar la inasistencia');
    this.exigir(EstadoCita.CONFIRMADA);
    asegurar(ahora >= this.inicio, 'La cita aún no comienza');
    this.estado = EstadoCita.NO_ASISTIO;
  }

  /** Parte que debe responder una propuesta pendiente. */
  get parteQueDebeResponder(): Parte | undefined {
    if (this.estado !== EstadoCita.PENDIENTE_ACEPTACION) return undefined;
    return this.propuestaPor === 'MEDICO' ? 'PACIENTE' : 'MEDICO';
  }

  private marcarCancelada(por: Cancelador, motivo: string, ahora: Date): void {
    this.estado = EstadoCita.CANCELADA;
    this.canceladaPor = por;
    this.motivoCancelacion = motivo?.trim() || 'Sin motivo';
    this.canceladaEn = ahora;
  }

  private exigir(estado: EstadoCita): void {
    if (this.estado !== estado) throw new ReglaNegocioError(`La cita está ${this.estado}; se esperaba ${estado}`);
  }

  private static validar(datos: DatosNuevaCita, ahora: Date): void {
    asegurar(datos.inicio > ahora, 'La fecha de la cita debe ser futura');
    asegurar(datos.fin > datos.inicio, 'Franja horaria inválida');
    asegurar(datos.monto > 0, 'El monto de la consulta debe ser mayor que cero');
  }

  private static base(datos: DatosNuevaCita) {
    return {
      pacienteId: datos.pacienteId,
      medicoId: datos.medicoId,
      agendadaPorUsuarioId: datos.agendadaPorUsuarioId,
      inicio: datos.inicio,
      fin: datos.fin,
      modalidad: datos.modalidad,
      motivo: (datos.motivo ?? '').trim(),
      monto: datos.monto,
      moneda: datos.moneda,
      politicaAplicada: datos.politica,
    };
  }
}
