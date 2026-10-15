import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { AuditoriaService } from '../application/auditoria.service';

/** «Boundary» El paciente consulta quién accedió a su información clínica. */
@ApiTags('Auditoría')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE, RolUsuario.ADMIN)
@Controller('auditoria')
export class AuditoriaController {
  constructor(
    private readonly auditoria: AuditoriaService,
    private readonly perfiles: PerfilesService,
  ) {}

  @Get('pacientes/:pacienteId')
  async accesos(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    await this.perfiles.asegurarGestion(actor, pacienteId);
    const registros = await this.auditoria.listarPorPaciente(pacienteId);
    return registros.map((r) => ({ id: r.id, fecha: r.fecha, ...r.entrada, ip: undefined }));
  }
}
