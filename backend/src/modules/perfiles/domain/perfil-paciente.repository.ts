import { PerfilPaciente } from './perfil-paciente';

/** «Repository» de perfiles de paciente (colección `pacientes`). */
export abstract class PerfilPacienteRepository {
  abstract guardar(perfil: PerfilPaciente): Promise<void>;
  abstract buscarPorId(id: string): Promise<PerfilPaciente | null>;
  abstract buscarPorIds(ids: string[]): Promise<PerfilPaciente[]>;
  abstract buscarPorTitular(usuarioId: string): Promise<PerfilPaciente[]>;
}
