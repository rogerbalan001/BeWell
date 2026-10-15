import { Body, Controller, Get, NotFoundException, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsInt, IsMongoId, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { ResenasService } from '../application/resenas.service';
import { ResenaVerificada } from '../domain/resena-verificada';

export class CalificacionesDto {
  @IsInt() @Min(1) @Max(5) puntualidad: number;
  @IsInt() @Min(1) @Max(5) trato: number;
  @IsInt() @Min(1) @Max(5) claridad: number;
  @IsInt() @Min(1) @Max(5) instalaciones: number;
  @IsOptional() @IsString() @MaxLength(1000) comentario?: string;
}

export class PublicarResenaDto extends CalificacionesDto {
  @IsMongoId() citaId: string;
}

/** «Boundary» ResenasController. */
@ApiTags('Reseñas verificadas')
@Controller('resenas')
export class ResenasController {
  constructor(
    private readonly resenas: ResenasService,
    private readonly perfiles: PerfilesService,
    private readonly reloj: Reloj,
  ) {}

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Post()
  async publicar(@ActorActual() actor: Actor, @Body() dto: PublicarResenaDto) {
    const { citaId, ...datos } = dto;
    return this.aRespuesta(await this.resenas.publicar(actor, citaId, datos), true);
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Patch(':id')
  async editar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: CalificacionesDto) {
    return this.aRespuesta(await this.resenas.editar(actor, id, dto), true);
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
  @Get('cita/:citaId')
  async deCita(@ActorActual() actor: Actor, @Param('citaId', ParseObjectIdPipe) citaId: string) {
    const r = await this.resenas.obtenerPorCita(actor, citaId);
    if (!r) throw new NotFoundException('La cita aún no tiene reseña');
    return this.aRespuesta(r, r.autorUsuarioId === actor.id);
  }

  @Publico()
  @Get('medico/:medicoId')
  async deMedico(@Param('medicoId', ParseObjectIdPipe) medicoId: string) {
    const { resenas, estadisticas } = await this.resenas.listarPorMedico(medicoId);
    const pacientes = new Map((await this.perfiles.obtenerVarios(resenas.map((r) => r.pacienteId))).map((p) => [p.id, p]));
    return {
      estadisticas,
      resenas: resenas.map((r) => {
        const p = pacientes.get(r.pacienteId);
        return { ...this.aRespuesta(r, false), autor: p ? `${p.nombres.split(' ')[0]} ${p.apellidos.charAt(0)}.` : 'Paciente' };
      }),
    };
  }

  private aRespuesta(r: ResenaVerificada, esAutor: boolean) {
    return {
      id: r.id,
      citaId: r.citaId,
      medicoId: r.medicoId,
      puntualidad: r.puntualidad,
      trato: r.trato,
      claridad: r.claridad,
      instalaciones: r.instalaciones,
      promedio: Math.round(r.promedio * 10) / 10,
      comentario: r.comentario,
      publicadaEn: r.publicadaEn,
      editadaEn: r.editadaEn,
      editable: esAutor && r.esEditable(this.reloj.ahora()),
    };
  }
}
