import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { aCentavos } from '../../../shared/domain/dinero';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../application/medicos.service';
import { ActualizarPerfilMedicoDto, aMedicoCompleto, aMedicoPublico, FiltrosDirectorioDto } from './dto/medico.dto';

/** «Boundary» Directorio de especialistas verificados y perfil del médico. */
@ApiTags('Médicos')
@Controller('medicos')
export class MedicosController {
  constructor(private readonly medicos: MedicosService) {}

  @Publico()
  @Get()
  async directorio(@Query() filtros: FiltrosDirectorioDto) {
    const lista = await this.medicos.directorio({
      especialidad: filtros.especialidad,
      texto: filtros.q,
      modalidad: filtros.modalidad,
    });
    return lista.map(aMedicoPublico);
  }

  @Publico()
  @Get('especialidades')
  especialidades(): Promise<string[]> {
    return this.medicos.listarEspecialidades();
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Get('yo')
  async yo(@ActorActual() actor: Actor) {
    return aMedicoCompleto(await this.medicos.delActor(actor));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Patch('yo')
  async actualizar(@ActorActual() actor: Actor, @Body() dto: ActualizarPerfilMedicoDto) {
    const medico = await this.medicos.actualizarPerfil(actor, {
      ...dto,
      tarifaConsulta: dto.tarifaConsulta ? aCentavos(dto.tarifaConsulta) : undefined,
    });
    return aMedicoCompleto(medico);
  }

  @Publico()
  @Get(':id')
  async perfil(@Param('id', ParseObjectIdPipe) id: string) {
    return aMedicoPublico(await this.medicos.obtenerPublico(id));
  }
}
