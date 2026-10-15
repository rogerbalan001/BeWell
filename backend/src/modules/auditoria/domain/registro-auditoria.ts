import { generarId } from '../../../shared/domain/id';
import { EntradaAuditoria } from '../../../shared/application/registro-auditoria';

/** «Entity» RegistroAuditoria: registro inmutable de un acceso a información clínica. */
export class RegistroAuditoriaEntidad {
  constructor(
    readonly id: string,
    readonly entrada: EntradaAuditoria,
    readonly fecha: Date,
  ) {}

  static crear(entrada: EntradaAuditoria, fecha: Date): RegistroAuditoriaEntidad {
    return new RegistroAuditoriaEntidad(generarId(), { ...entrada, accesoEmergencia: !!entrada.accesoEmergencia }, fecha);
  }
}

/** «Repository» de solo inserción: no expone métodos de modificación ni borrado. */
export abstract class AuditoriaRepository {
  abstract insertar(registro: RegistroAuditoriaEntidad): Promise<void>;
  abstract listarPorPaciente(pacienteId: string, limite: number): Promise<RegistroAuditoriaEntidad[]>;
}
