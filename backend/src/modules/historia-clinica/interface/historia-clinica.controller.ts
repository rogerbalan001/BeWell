import { Body, Controller, Get, Param, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Medico } from '../../medicos/domain/medico';
import { HistoriaClinicaService } from '../application/historia-clinica.service';
import {
  aAntecedentesRespuesta,
  AntecedentesClinicosDto,
  aConsultaRespuesta,
  aHistoriaRespuesta,
  ContenidoConsultaDto,
  NuevaConsultaDto,
} from './dto/historia-clinica.dto';

/**
 * «Boundary» HistoriaClinicaController. HU: historia clínica del paciente
 * (antecedentes + historia de cada consulta), con el mismo control de
 * privacidad del expediente.
 */
@ApiTags('Historia clínica')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
@Controller('historias-clinicas')
export class HistoriaClinicaController {
  constructor(
    private readonly historia: HistoriaClinicaService,
    private readonly medicos: MedicosService,
  ) {}

  @Get(':pacienteId')
  async obtener(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    const vista = await this.historia.obtener(actor, pacienteId);
    return aHistoriaRespuesta(vista, await this.mapaMedicos(vista.consultas.map((c) => c.medicoId)), actor.medicoId);
  }

  @Put(':pacienteId/antecedentes')
  async actualizarAntecedentes(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Body() dto: AntecedentesClinicosDto,
  ) {
    return aAntecedentesRespuesta(await this.historia.actualizarAntecedentes(actor, pacienteId, dto));
  }

  @Roles(RolUsuario.MEDICO)
  @Post(':pacienteId/consultas')
  async registrarConsulta(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Body() dto: NuevaConsultaDto,
  ) {
    const { fecha, signosVitales, ...resto } = dto;
    const c = await this.historia.registrarConsulta(actor, pacienteId, {
      ...resto,
      listaProblemas: dto.listaProblemas ?? [],
      signosVitales: signosVitales ?? {},
      examenFisico: dto.examenFisico ?? '',
      fecha: fecha ? new Date(fecha) : undefined,
    });
    return aConsultaRespuesta(c, await this.mapaMedicos([c.medicoId]), actor.medicoId);
  }

  @Get(':pacienteId/consultas/:consultaId')
  async consulta(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Param('consultaId', ParseObjectIdPipe) consultaId: string,
  ) {
    const c = await this.historia.obtenerConsulta(actor, pacienteId, consultaId);
    return aConsultaRespuesta(c, await this.mapaMedicos([c.medicoId]), actor.medicoId);
  }

  @Roles(RolUsuario.MEDICO)
  @Put(':pacienteId/consultas/:consultaId')
  async corregirConsulta(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Param('consultaId', ParseObjectIdPipe) consultaId: string,
    @Body() dto: ContenidoConsultaDto,
  ) {
    const c = await this.historia.corregirConsulta(actor, pacienteId, consultaId, {
      ...dto,
      listaProblemas: dto.listaProblemas ?? [],
      signosVitales: dto.signosVitales ?? {},
      examenFisico: dto.examenFisico ?? '',
    });
    return aConsultaRespuesta(c, await this.mapaMedicos([c.medicoId]), actor.medicoId);
  }

  /** Exporta la historia clínica en PDF; responde con una URL de descarga firmada (5 min). */
  @Post(':pacienteId/exportar')
  async exportar(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    return { url: await this.historia.exportarPdf(actor, pacienteId) };
  }

  private async mapaMedicos(ids: string[]): Promise<Map<string, Medico>> {
    const lista = await this.medicos.obtenerVarios([...new Set(ids)]);
    return new Map(lista.map((m) => [m.id, m]));
  }
}
