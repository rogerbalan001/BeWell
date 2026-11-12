import { Pago } from '../domain/pago';

/** Paciente y médico de un pago, con lo necesario para mostrarlos y avisarles. */
export interface ParticipantesPago {
  pacienteNombre: string;
  /** Titular que gestiona el perfil del paciente: recibe los avisos. */
  pacienteUsuarioId: string;
  medicoNombre: string;
  medicoUsuarioId: string;
}

/**
 * Puerto para conocer a las partes de un pago sin que el módulo de pagos
 * dependa de cómo se guardan perfiles y médicos.
 */
export abstract class ParticipantesPagoPuerto {
  abstract de(pago: Pago): Promise<ParticipantesPago>;
}
