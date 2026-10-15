import { Body, Controller, Get, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico, Roles } from '../../../shared/interface/auth/decoradores';
import { AgendaService } from '../application/agenda.service';
import { Medico } from '../domain/medico';
import { CATALOGO_POLITICAS, PoliticaCancelacion, TipoPolitica } from '../domain/politica-cancelacion';
import { aPoliticaRespuesta, ConfigurarHorarioDto, ConfigurarPoliticaDto } from './dto/medico.dto';

const aAgenda = (m: Medico) => ({
  horario: m.horario,
  modalidades: m.modalidades,
  zonaHorariaMin: m.zonaHorariaMin,
  politicaCancelacion: aPoliticaRespuesta(m),
});

/** «Boundary» HU: configurar mi política de cancelación (y mi horario). */
@ApiTags('Agenda del médico')
@Controller('agenda')
export class AgendaController {
  constructor(private readonly agenda: AgendaService) {}

  @Publico()
  @Get('politicas')
  catalogoPoliticas() {
    return (Object.keys(CATALOGO_POLITICAS) as TipoPolitica[]).map((tipo) => {
      const p = PoliticaCancelacion.desdeTipo(tipo);
      return { tipo, horasMinimasAviso: p.horasMinimasAviso, porcentajePenalizacion: p.porcentajePenalizacion, descripcion: p.descripcion };
    });
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Get()
  async obtener(@ActorActual() actor: Actor) {
    return aAgenda(await this.agenda.obtenerAgenda(actor));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Put('horario')
  async configurarHorario(@ActorActual() actor: Actor, @Body() dto: ConfigurarHorarioDto) {
    return aAgenda(await this.agenda.configurarHorario(actor, dto.bloques, dto.modalidades));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @Put('politica')
  async configurarPoliticaCancelacion(@ActorActual() actor: Actor, @Body() dto: ConfigurarPoliticaDto) {
    return aAgenda(await this.agenda.configurarPolitica(actor, dto.tipo));
  }
}
