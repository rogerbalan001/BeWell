import { Cita, EstadoCita } from './cita';

export interface FiltrosCitas {
  estados?: EstadoCita[];
  desde?: Date;
  hasta?: Date;
}

/** «Repository» de citas (colección `citas`). */
export abstract class CitaRepository {
  /** Lanza error de clave duplicada si la franja ya está ocupada (índice único parcial). */
  abstract guardar(cita: Cita): Promise<void>;
  abstract buscarPorId(id: string): Promise<Cita | null>;
  abstract existeSolapamiento(medicoId: string, inicio: Date, fin: Date, excluirId?: string): Promise<boolean>;
  abstract buscarOcupadas(medicoId: string, desde: Date, hasta: Date): Promise<Cita[]>;
  abstract listarPorPacientes(pacienteIds: string[], filtros: FiltrosCitas): Promise<Cita[]>;
  abstract listarPorMedico(medicoId: string, filtros: FiltrosCitas): Promise<Cita[]>;
  abstract buscarPropuestasVencidas(ahora: Date): Promise<Cita[]>;
  abstract existeAtendida(pacienteId: string, medicoId: string): Promise<boolean>;
}
