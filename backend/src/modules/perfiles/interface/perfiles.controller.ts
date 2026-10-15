import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { PerfilesService } from '../application/perfiles.service';
import { ActualizarPerfilDto, aPerfilRespuesta, CrearPerfilFamiliarDto, PerfilRespuesta } from './dto/perfil.dto';

/** «Boundary» HU: gestionar los perfiles de mis hijos o padres desde mi cuenta. */
@ApiTags('Perfiles familiares')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE)
@Controller('perfiles')
export class PerfilesController {
  constructor(private readonly perfiles: PerfilesService) {}

  @Get()
  async listarPerfiles(@ActorActual() actor: Actor): Promise<PerfilRespuesta[]> {
    return (await this.perfiles.listarPerfiles(actor.id)).map((p) => aPerfilRespuesta(p));
  }

  @Post()
  async crearPerfilFamiliar(@ActorActual() actor: Actor, @Body() dto: CrearPerfilFamiliarDto): Promise<PerfilRespuesta> {
    const datos = Object.assign(new CrearPerfilFamiliarDto(), dto).aDominio();
    return aPerfilRespuesta(await this.perfiles.crearPerfilFamiliar(actor.id, dto.parentescoConTitular, datos));
  }

  @Get(':id')
  async obtener(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string): Promise<PerfilRespuesta> {
    return aPerfilRespuesta(await this.perfiles.asegurarGestion(actor, id));
  }

  @Patch(':id')
  async actualizar(
    @ActorActual() actor: Actor,
    @Param('id', ParseObjectIdPipe) id: string,
    @Body() dto: ActualizarPerfilDto,
  ): Promise<PerfilRespuesta> {
    const perfil = await this.perfiles.actualizar(actor, id, {
      ...dto,
      fechaNacimiento: dto.fechaNacimiento ? new Date(dto.fechaNacimiento) : undefined,
    });
    return aPerfilRespuesta(perfil);
  }
}
