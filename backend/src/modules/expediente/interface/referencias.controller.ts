import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { ReferenciasService } from '../application/referencias.service';
import { ReferenciaEspecialista } from '../domain/referencia-especialista';
import { aMedicoResumen, ReferirDto } from './dto/expediente.dto';

/** «Boundary» HU: referir pacientes a especialistas de la red. */
@ApiTags('Referencias')
@ApiBearerAuth()
@Controller('referencias')
export class ReferenciasController {
  constructor(
    private readonly referencias: ReferenciasService,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
  ) {}

  @Roles(RolUsuario.MEDICO)
  @Post()
  async referirAEspecialista(@ActorActual() actor: Actor, @Body() dto: ReferirDto) {
    return (await this.enriquecer([await this.referencias.referir(actor, dto)]))[0];
  }

  @Roles(RolUsuario.MEDICO, RolUsuario.PACIENTE)
  @Get()
  async listar(@ActorActual() actor: Actor) {
    return this.enriquecer(await this.referencias.listar(actor));
  }

  @Roles(RolUsuario.PACIENTE)
  @Post(':id/aprobar')
  async aprobar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.enriquecer([await this.referencias.aprobar(actor, id)]))[0];
  }

  @Roles(RolUsuario.PACIENTE)
  @Post(':id/rechazar')
  async rechazar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.enriquecer([await this.referencias.rechazar(actor, id)]))[0];
  }

  private async enriquecer(lista: ReferenciaEspecialista[]) {
    const [medicos, pacientes] = await Promise.all([
      this.medicos.obtenerVarios(lista.flatMap((r) => [r.medicoOrigenId, r.medicoDestinoId])),
      this.perfiles.obtenerVarios(lista.map((r) => r.pacienteId)),
    ]);
    const m = new Map(medicos.map((x) => [x.id, x]));
    const p = new Map(pacientes.map((x) => [x.id, x]));
    return lista.map((r) => ({
      id: r.id,
      pacienteId: r.pacienteId,
      pacienteNombre: p.get(r.pacienteId)?.nombreCompleto,
      medicoOrigen: aMedicoResumen(m.get(r.medicoOrigenId)),
      medicoDestino: aMedicoResumen(m.get(r.medicoDestinoId)),
      especialidadDestino: r.especialidadDestino,
      motivo: r.motivo,
      estado: r.estado,
      fecha: r.fecha,
      respondidaEn: r.respondidaEn,
    }));
  }
}
