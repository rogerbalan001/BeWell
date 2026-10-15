import { Body, Controller, Delete, Get, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Medico } from '../../medicos/domain/medico';
import { aPerfilRespuesta } from '../../perfiles/interface/dto/perfil.dto';
import { ExpedienteService } from '../application/expediente.service';
import {
  aEventoRespuesta,
  AgregarEventoDto,
  AntecedentesDto,
  aPermisoRespuesta,
  ConcederAccesoDto,
  FiltrosLineaTiempoDto,
} from './dto/expediente.dto';

/**
 * «Boundary» ExpedienteController. HU: ser dueño de mi expediente; línea de
 * tiempo para el médico; decidir qué médico ve qué parte y por cuánto tiempo.
 */
@ApiTags('Expediente clínico')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
@Controller('expedientes')
export class ExpedienteController {
  constructor(
    private readonly expediente: ExpedienteService,
    private readonly medicos: MedicosService,
  ) {}

  @Roles(RolUsuario.MEDICO)
  @Get('medico/pacientes')
  async misPacientes(@ActorActual() actor: Actor) {
    const lista = await this.expediente.pacientesAutorizados(actor);
    return lista.map(({ paciente, permisos }) => ({
      paciente: aPerfilRespuesta(paciente),
      categorias: [...new Set(permisos.flatMap((p) => p.categoriasPermitidas))],
      escritura: permisos.some((p) => p.escritura),
      validoHasta: new Date(Math.max(...permisos.map((p) => p.validoHasta.getTime()))),
    }));
  }

  @Get(':pacienteId')
  async resumen(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    const { expediente, paciente, acceso } = await this.expediente.resumen(actor, pacienteId);
    return {
      id: expediente.id,
      paciente: aPerfilRespuesta(paciente),
      antecedentes: expediente.antecedentes,
      actualizadoEn: expediente.actualizadoEn,
      acceso,
    };
  }

  /** Exporta el expediente en PDF; responde con una URL de descarga firmada (5 min). */
  @Post(':pacienteId/exportar')
  async exportar(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    return { url: await this.expediente.exportarPdf(actor, pacienteId) };
  }

  @Put(':pacienteId/antecedentes')
  async antecedentes(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Body() dto: AntecedentesDto,
  ) {
    const e = await this.expediente.actualizarAntecedentes(actor, pacienteId, dto.antecedentes);
    return { id: e.id, antecedentes: e.antecedentes, actualizadoEn: e.actualizadoEn };
  }

  @Get(':pacienteId/linea-tiempo')
  async obtenerLineaDeTiempo(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Query() filtros: FiltrosLineaTiempoDto,
  ) {
    const r = await this.expediente.obtenerLineaDeTiempo(actor, pacienteId, filtros);
    const medicos = await this.mapaMedicos(r.items.map((e) => e.medicoId));
    return {
      items: r.items.map((e) => aEventoRespuesta(e, medicos)),
      total: r.total,
      pagina: r.pagina,
      tamano: r.tamano,
      categoriasPermitidas: r.acceso.categorias,
      esTitular: r.acceso.esTitular,
    };
  }

  @Get(':pacienteId/eventos/:eventoId')
  async evento(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Param('eventoId', ParseObjectIdPipe) eventoId: string,
  ) {
    const e = await this.expediente.obtenerEvento(actor, pacienteId, eventoId);
    return aEventoRespuesta(e, await this.mapaMedicos([e.medicoId]));
  }

  @Post(':pacienteId/eventos')
  async agregarEvento(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Body() dto: AgregarEventoDto,
  ) {
    const e = await this.expediente.agregarEvento(actor, pacienteId, { ...dto, fecha: new Date(dto.fecha) });
    return aEventoRespuesta(e, await this.mapaMedicos([e.medicoId]));
  }

  @Roles(RolUsuario.PACIENTE)
  @Get(':pacienteId/permisos')
  async permisos(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    const permisos = await this.expediente.listarPermisos(actor, pacienteId);
    const medicos = await this.mapaMedicos(permisos.map((p) => p.medicoId));
    return permisos.map((p) => aPermisoRespuesta(p, medicos));
  }

  @Roles(RolUsuario.PACIENTE)
  @Post(':pacienteId/permisos')
  async concederAcceso(
    @ActorActual() actor: Actor,
    @Param('pacienteId', ParseObjectIdPipe) pacienteId: string,
    @Body() dto: ConcederAccesoDto,
  ) {
    const p = await this.expediente.concederAcceso(actor, pacienteId, {
      medicoId: dto.medicoId,
      categorias: dto.categorias,
      validoHasta: new Date(dto.validoHasta),
      escritura: dto.escritura ?? false,
    });
    return aPermisoRespuesta(p, await this.mapaMedicos([p.medicoId]));
  }

  @Roles(RolUsuario.PACIENTE)
  @Delete('permisos/:permisoId')
  async revocarAcceso(@ActorActual() actor: Actor, @Param('permisoId', ParseObjectIdPipe) permisoId: string) {
    const p = await this.expediente.revocarAcceso(actor, permisoId);
    return aPermisoRespuesta(p, await this.mapaMedicos([p.medicoId]));
  }

  private async mapaMedicos(ids: (string | undefined)[]): Promise<Map<string, Medico>> {
    const lista = await this.medicos.obtenerVarios(ids.filter((x): x is string => !!x));
    return new Map(lista.map((m) => [m.id, m]));
  }
}
