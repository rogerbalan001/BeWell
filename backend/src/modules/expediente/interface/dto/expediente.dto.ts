import { Type } from 'class-transformer';
import {
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { CategoriaClinica, TipoEvento } from '../../domain/categoria-clinica';
import { EventoClinico } from '../../domain/evento-clinico';
import { PermisoAcceso } from '../../domain/permiso-acceso';
import { Medico } from '../../../medicos/domain/medico';

export class FiltrosLineaTiempoDto {
  @IsOptional() @IsEnum(TipoEvento) tipo?: TipoEvento;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) pagina?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) tamano?: number;
}

export class AgregarEventoDto {
  @IsEnum(TipoEvento) tipo: TipoEvento;
  @IsOptional() @IsEnum(CategoriaClinica) categoria?: CategoriaClinica;
  @IsString() @IsNotEmpty() @MaxLength(150) titulo: string;
  @IsString() @MaxLength(5000) resumen: string;
  @IsDateString() fecha: string;
  @IsOptional() @IsObject() detalles?: Record<string, string>;
}

export class AntecedentesDto {
  @IsArray() @IsString({ each: true }) @MaxLength(300, { each: true }) antecedentes: string[];
}

export class ConcederAccesoDto {
  @IsMongoId() medicoId: string;
  @IsArray() @ArrayNotEmpty() @IsEnum(CategoriaClinica, { each: true }) categorias: CategoriaClinica[];
  @IsDateString() validoHasta: string;
  @IsOptional() @IsBoolean() escritura?: boolean;
}

export class ReferirDto {
  @IsMongoId() pacienteId: string;
  @IsMongoId() medicoDestinoId: string;
  @IsString() @IsNotEmpty() @MaxLength(2000) motivo: string;
}

export const aMedicoResumen = (m?: Medico) =>
  m ? { id: m.id, nombreCompleto: m.nombreCompleto, especialidad: m.especialidades[0], verificado: m.estaVerificado() } : undefined;

export const aEventoRespuesta = (e: EventoClinico, medicos: Map<string, Medico>) => ({
  id: e.id,
  pacienteId: e.pacienteId,
  tipo: e.tipo,
  categoria: e.categoria,
  fecha: e.fecha,
  titulo: e.titulo,
  resumen: e.resumen,
  medico: e.medicoId ? aMedicoResumen(medicos.get(e.medicoId)) : undefined,
  documentoOrigenId: e.documentoOrigenId,
  detalles: e.detalles,
  autoReportado: e.detalles?.autoReportado === 'true',
});

export const aPermisoRespuesta = (p: PermisoAcceso, medicos: Map<string, Medico>, ahora = new Date()) => ({
  id: p.id,
  pacienteId: p.pacienteId,
  medico: aMedicoResumen(medicos.get(p.medicoId)),
  categorias: p.categoriasPermitidas,
  escritura: p.escritura,
  validoHasta: p.validoHasta,
  revocado: p.revocado,
  revocadoEn: p.revocadoEn,
  vigente: p.estaVigente(ahora),
  origen: p.origen,
  creadoEn: p.creadoEn,
});
