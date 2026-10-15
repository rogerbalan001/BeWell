import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { aMonto } from '../../../shared/domain/dinero';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PagosService } from '../../pagos/application/pagos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { CitasService } from '../application/citas.service';
import { Cita } from '../domain/cita';
import {
  aCitaRespuesta,
  AgendarCitaDto,
  AtenderCitaDto,
  CancelarCitaDto,
  DisponibilidadDto,
  FiltrosCitasDto,
  ProponerCitaDto,
  ReportarProblemaDto,
} from './dto/cita.dto';

/** «Boundary» CitasController. HU: agendar, cancelar con política, seguimiento y pago retenido. */
@ApiTags('Citas')
@Controller('citas')
export class CitasController {
  constructor(
    private readonly citas: CitasService,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
    private readonly pagos: PagosService,
  ) {}

  @Publico()
  @Get('disponibilidad')
  async consultarDisponibilidad(@Query() dto: DisponibilidadDto) {
    const franjas = await this.citas.consultarDisponibilidad(dto.medicoId, dto.desde ? new Date(dto.desde) : undefined, dto.dias ?? 7);
    return franjas.map((f) => ({ inicio: f.inicio, fin: f.fin }));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Get()
  async listar(@ActorActual() actor: Actor, @Query() f: FiltrosCitasDto) {
    const lista = await this.citas.listar(actor, {
      pacienteId: f.pacienteId,
      estados: f.estados,
      desde: f.desde ? new Date(f.desde) : undefined,
      hasta: f.hasta ? new Date(f.hasta) : undefined,
    });
    return this.responder(lista);
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Post()
  async agendar(@ActorActual() actor: Actor, @Body() dto: AgendarCitaDto) {
    const cita = await this.citas.agendar(actor, { ...dto, inicio: new Date(dto.inicio), motivo: dto.motivo ?? '' });
    return (await this.responder([cita]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Post('propuestas')
  async proponer(@ActorActual() actor: Actor, @Body() dto: ProponerCitaDto) {
    const cita = await this.citas.proponer(actor, { ...dto, inicio: new Date(dto.inicio) });
    return (await this.responder([cita]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Get(':id')
  async obtener(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    const cita = await this.citas.obtenerParaActor(actor, id);
    const reembolsoSiCancelaAhora = await this.citas.simularCancelacion(actor, id);
    return { ...(await this.responder([cita]))[0], reembolsoSiCancelaAhora: aMonto(reembolsoSiCancelaAhora) };
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/cancelar')
  async cancelar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: CancelarCitaDto) {
    const { cita, reembolso } = await this.citas.cancelar(actor, id, dto.motivo);
    return { ...(await this.responder([cita]))[0], reembolso: aMonto(reembolso) };
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/atender')
  async marcarAtendida(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: AtenderCitaDto) {
    return (await this.responder([await this.citas.marcarAtendida(actor, id, dto)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/no-asistio')
  async noAsistio(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.responder([await this.citas.marcarNoAsistio(actor, id)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @HttpCode(200)
  @Post(':id/reportar-problema')
  async reportarProblema(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: ReportarProblemaDto) {
    await this.citas.reportarProblema(actor, id, dto.motivo);
    return (await this.responder([await this.citas.obtenerPorId(id)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/aceptar')
  async aceptar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.responder([await this.citas.aceptarPropuesta(actor, id)]))[0];
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @HttpCode(200)
  @Post(':id/rechazar')
  async rechazar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return (await this.responder([await this.citas.rechazarPropuesta(actor, id)]))[0];
  }

  private async responder(lista: Cita[]) {
    const [medicos, pacientes, pagos] = await Promise.all([
      this.medicos.obtenerVarios(lista.map((c) => c.medicoId)),
      this.perfiles.obtenerVarios(lista.map((c) => c.pacienteId)),
      this.pagos.obtenerPorCitas(lista.map((c) => c.id)),
    ]);
    const ctx = {
      medicos: new Map(medicos.map((m) => [m.id, m])),
      pacientes: new Map(pacientes.map((p) => [p.id, p])),
      pagos: new Map(pagos.map((p) => [p.citaId, p])),
    };
    return lista.map((c) => aCitaRespuesta(c, ctx));
  }
}
