import { Modalidad, Medico } from './medico';

export interface FiltrosDirectorio {
  especialidad?: string;
  texto?: string;
  modalidad?: Modalidad;
}

/** «Repository» de médicos (colección `medicos`). */
export abstract class MedicoRepository {
  abstract guardar(medico: Medico): Promise<void>;
  abstract buscarPorId(id: string): Promise<Medico | null>;
  abstract buscarPorIds(ids: string[]): Promise<Medico[]>;
  abstract buscarPorUsuario(usuarioId: string): Promise<Medico | null>;
  /** Solo médicos APROBADOS. */
  abstract buscarDirectorio(filtros: FiltrosDirectorio): Promise<Medico[]>;
  abstract buscarConCredencialesPendientes(): Promise<Medico[]>;
  abstract listarEspecialidades(): Promise<string[]>;
}
