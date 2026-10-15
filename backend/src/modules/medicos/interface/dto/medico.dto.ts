import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { aMonto } from '../../../../shared/domain/dinero';
import { BloqueHorario } from '../../domain/bloque-horario';
import { CredencialProfesional } from '../../domain/credencial-profesional';
import { Medico, Modalidad } from '../../domain/medico';
import { TipoPolitica } from '../../domain/politica-cancelacion';

export class FiltrosDirectorioDto {
  @IsOptional() @IsString() especialidad?: string;
  @IsOptional() @IsString() @MaxLength(80) q?: string;
  @IsOptional() @IsIn(['PRESENCIAL', 'VIRTUAL']) modalidad?: Modalidad;
}

export class ActualizarPerfilMedicoDto {
  @IsOptional() @IsArray() @IsString({ each: true }) especialidades?: string[];
  @IsOptional() @IsNumber() @Min(1) tarifaConsulta?: number;
  @IsOptional() @IsString() @MaxLength(200) direccionConsultorio?: string;
  @IsOptional() @IsString() @MaxLength(1000) biografia?: string;
  @IsOptional() @IsArray() @IsIn(['PRESENCIAL', 'VIRTUAL'], { each: true }) modalidades?: Modalidad[];
}

export class BloqueHorarioDto implements BloqueHorario {
  @IsInt() @Min(0) @Max(6) diaSemana: number;
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/) horaInicio: string;
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/) horaFin: string;
  @IsInt() @Min(15) @Max(240) duracionCitaMin: number;
}

export class ConfigurarHorarioDto {
  @IsArray() @ValidateNested({ each: true }) @Type(() => BloqueHorarioDto) bloques: BloqueHorarioDto[];
  @IsOptional() @IsArray() @ArrayNotEmpty() @IsIn(['PRESENCIAL', 'VIRTUAL'], { each: true }) modalidades?: Modalidad[];
}

export class ConfigurarPoliticaDto {
  @IsIn(['FLEXIBLE', 'MODERADA', 'ESTRICTA']) tipo: TipoPolitica;
}

export class RegistrarCredencialDto {
  @IsIn(['TITULO', 'COLEGIATURA', 'CEDULA']) tipo: 'TITULO' | 'COLEGIATURA' | 'CEDULA';
  @IsString() @IsNotEmpty() @MaxLength(40) numero: string;
}

export class RechazarCredencialDto {
  @IsString() @IsNotEmpty() @MaxLength(300) motivo: string;
}

export const aPoliticaRespuesta = (m: Medico) => ({
  tipo: m.politicaCancelacion.tipo,
  horasMinimasAviso: m.politicaCancelacion.horasMinimasAviso,
  porcentajePenalizacion: m.politicaCancelacion.porcentajePenalizacion,
  descripcion: m.politicaCancelacion.descripcion,
});

/** Vista pública (directorio y perfil). */
export const aMedicoPublico = (m: Medico) => ({
  id: m.id,
  nombres: m.nombres,
  apellidos: m.apellidos,
  nombreCompleto: m.nombreCompleto,
  especialidades: m.especialidades,
  tarifaConsulta: aMonto(m.tarifaConsulta),
  moneda: m.moneda,
  verificado: m.estaVerificado(),
  calificacionPromedio: m.calificacionPromedio,
  totalResenas: m.totalResenas,
  modalidades: m.modalidades,
  direccionConsultorio: m.direccionConsultorio,
  biografia: m.biografia,
  tieneHorario: m.horario.length > 0,
  politicaCancelacion: aPoliticaRespuesta(m),
});

const aCredencialRespuesta = (c: CredencialProfesional) => ({
  id: c.id,
  tipo: c.tipo,
  numero: c.numero,
  estado: c.estado,
  enviadaEn: c.enviadaEn,
  fechaRevision: c.fechaRevision,
  observaciones: c.observaciones,
});

/** Vista completa (el propio médico y el administrador). */
export const aMedicoCompleto = (m: Medico) => ({
  ...aMedicoPublico(m),
  usuarioId: m.usuarioId,
  estadoVerificacion: m.estadoVerificacion,
  credenciales: m.credenciales.map(aCredencialRespuesta),
  horario: m.horario,
  zonaHorariaMin: m.zonaHorariaMin,
});
