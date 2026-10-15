import { Injectable, Logger } from '@nestjs/common';
import { EntradaAuditoria, RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { Reloj } from '../../../shared/domain/reloj';
import { AuditoriaRepository, RegistroAuditoriaEntidad } from '../domain/registro-auditoria';

/** «Control» AuditoriaService: implementa el puerto RegistroAuditoria para todos los módulos. */
@Injectable()
export class AuditoriaService extends RegistroAuditoria {
  private readonly logger = new Logger(AuditoriaService.name);

  constructor(
    private readonly repositorio: AuditoriaRepository,
    private readonly reloj: Reloj,
  ) {
    super();
  }

  async registrar(entrada: EntradaAuditoria): Promise<void> {
    try {
      await this.repositorio.insertar(RegistroAuditoriaEntidad.crear(entrada, this.reloj.ahora()));
    } catch (e) {
      // La auditoría no debe tumbar la operación clínica, pero sí quedar en logs.
      this.logger.error(`No se pudo registrar auditoría: ${(e as Error).message}`);
    }
  }

  listarPorPaciente(pacienteId: string, limite = 50): Promise<RegistroAuditoriaEntidad[]> {
    return this.repositorio.listarPorPaciente(pacienteId, Math.min(limite, 200));
  }
}
