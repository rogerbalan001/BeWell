import { Body, Controller, Get, Param, Post, Put, Query, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsDateString,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ArchivoSubido, validarArchivo } from '../../../shared/interface/http/archivo-subido';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { MedicosService } from '../../medicos/application/medicos.service';
import { aMedicoResumen } from '../../expediente/interface/dto/expediente.dto';
import { ExamenesService } from '../application/examenes.service';
import { CATALOGO_EXAMENES } from '../domain/catalogo-examenes';
import { ExamenMedico } from '../domain/examen-medico';
import { SolicitudExamen } from '../domain/solicitud-examen';

export class SolicitarExamenesDto {
  @IsMongoId() pacienteId: string;
  @IsArray() @ArrayNotEmpty() @IsString({ each: true }) examenes: string[];
  @IsOptional() @IsString() @MaxLength(1000) indicaciones?: string;
  @IsOptional() @IsMongoId() citaId?: string;
}

/** Campos de texto del multipart de carga. */
export class CargarExamenDto {
  @IsMongoId() pacienteId: string;
  @IsString() @IsNotEmpty() @MaxLength(150) titulo: string;
  @IsOptional() @IsMongoId() solicitudId?: string;
  @IsOptional() @IsDateString() fechaExamen?: string;
}

export class ResultadoDto {
  @IsString() @IsNotEmpty() @MaxLength(100) analito: string;
  @IsString() @IsNotEmpty() @MaxLength(50) valor: string;
  @IsOptional() @IsString() @MaxLength(30) unidad?: string;
  @IsOptional() @IsString() @MaxLength(60) rangoReferencia?: string;
}

export class ConfirmarResultadosDto {
  @IsArray() @ValidateNested({ each: true }) @Type(() => ResultadoDto) resultados: ResultadoDto[];
}

export class FiltroPacienteDto {
  @IsOptional() @IsMongoId() pacienteId?: string;
}

const aExamenRespuesta = (e: ExamenMedico) => ({
  id: e.id,
  pacienteId: e.pacienteId,
  solicitudId: e.solicitudId,
  titulo: e.titulo,
  fechaExamen: e.fechaExamen,
  tipoMime: e.tipoMime,
  nombreArchivo: e.nombreArchivo,
  tamanoBytes: e.tamanoBytes,
  estadoExtraccion: e.estadoExtraccion,
  resultados: e.resultados,
  validadoPorMedico: !!e.validadoPorMedicoId,
  cargadoEn: e.cargadoEn,
});

/** «Boundary» ExamenesController. */
@ApiTags('Exámenes')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
@Controller('examenes')
export class ExamenesController {
  constructor(
    private readonly examenes: ExamenesService,
    private readonly medicos: MedicosService,
  ) {}

  @Get('catalogo')
  catalogo() {
    return CATALOGO_EXAMENES;
  }

  @Roles(RolUsuario.MEDICO)
  @Post('solicitudes')
  async solicitarExamenes(@ActorActual() actor: Actor, @Body() dto: SolicitarExamenesDto) {
    return (await this.solicitudesRespuesta([await this.examenes.solicitar(actor, dto)]))[0];
  }

  @Get('solicitudes')
  async solicitudes(@ActorActual() actor: Actor, @Query() q: FiltroPacienteDto) {
    return this.solicitudesRespuesta(await this.examenes.listarSolicitudes(actor, q.pacienteId));
  }

  /** Carga de PDF/JPG/PNG (≤ 10 MB). Responde con los valores extraídos para que el paciente los revise. */
  @Post()
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('archivo', { limits: { fileSize: 10 * 1024 * 1024 } }))
  async confirmarCarga(@ActorActual() actor: Actor, @Body() dto: CargarExamenDto, @UploadedFile() archivo: ArchivoSubido) {
    const valido = validarArchivo(archivo);
    const examen = await this.examenes.cargar(
      actor,
      { ...dto, fechaExamen: dto.fechaExamen ? new Date(dto.fechaExamen) : undefined },
      { contenido: valido.buffer, tipoMime: valido.mimetype, nombreOriginal: valido.originalname },
    );
    return aExamenRespuesta(examen);
  }

  @Get()
  async listar(@ActorActual() actor: Actor, @Query() q: FiltroPacienteDto) {
    if (!q.pacienteId) return [];
    return (await this.examenes.listar(actor, q.pacienteId)).map(aExamenRespuesta);
  }

  @Get(':id')
  async obtenerResultados(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return aExamenRespuesta(await this.examenes.obtener(actor, id));
  }

  /** URL temporal (5 min) para ver o descargar el archivo original. */
  @Get(':id/archivo')
  async archivo(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return { url: await this.examenes.urlArchivo(actor, id) };
  }

  @Roles(RolUsuario.PACIENTE)
  @Put(':id/resultados')
  async confirmarResultados(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string, @Body() dto: ConfirmarResultadosDto) {
    return aExamenRespuesta(await this.examenes.confirmarResultados(actor, id, dto.resultados));
  }

  @Roles(RolUsuario.MEDICO)
  @Post(':id/validar')
  async validar(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string) {
    return aExamenRespuesta(await this.examenes.validarResultados(actor, id));
  }

  private async solicitudesRespuesta(lista: SolicitudExamen[]) {
    const medicos = new Map((await this.medicos.obtenerVarios(lista.map((s) => s.medicoId))).map((m) => [m.id, m]));
    return lista.map((s) => ({
      id: s.id,
      pacienteId: s.pacienteId,
      medico: aMedicoResumen(medicos.get(s.medicoId)),
      citaId: s.citaId,
      examenes: s.examenes,
      indicaciones: s.indicaciones,
      estado: s.estado,
      examenResultadoIds: s.examenResultadoIds,
      creadaEn: s.creadaEn,
      completadaEn: s.completadaEn,
    }));
  }
}
