import { Transform, Type } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsEnum,
  IsIn,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { aMonto } from '../../../../shared/domain/dinero';
import { Medico, Modalidad } from '../../../medicos/domain/medico';
import { Pago } from '../../../pagos/domain/pago';
import { aPagoRespuesta } from '../../../pagos/interface/pagos.controller';
import { PerfilPaciente } from '../../../perfiles/domain/perfil-paciente';
import { Cita, EstadoCita } from '../../domain/cita';

export class DisponibilidadDto {
  @IsMongoId() medicoId: string;
  /** ISO 8601. Por defecto, ahora. */
  @IsOptional() @IsDateString() desde?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(31) dias?: number;
}

export class AgendarCitaDto {
  @IsMongoId() medicoId: string;
  @IsMongoId() pacienteId: string;
  @IsDateString() inicio: string;
  @IsIn(['PRESENCIAL', 'VIRTUAL']) modalidad: Modalidad;
  @IsOptional() @IsString() @MaxLength(1000) motivo?: string;
}

export class ProponerCitaDto {
  @IsMongoId() pacienteId: string;
  @IsOptional() @IsMongoId() medicoId?: string;
  @IsDateString() inicio: string;
  @IsIn(['PRESENCIAL', 'VIRTUAL']) modalidad: Modalidad;
  @IsOptional() @IsString() @MaxLength(1000) motivo?: string;
  @IsOptional() @IsMongoId() citaOrigenId?: string;
  @IsOptional() @IsMongoId() referenciaId?: string;
}

export class CancelarCitaDto {
  @IsString() @IsNotEmpty() @MaxLength(500) motivo: string;
}

export class AtenderCitaDto {
  @IsOptional() @IsString() @MaxLength(5000) notaClinica?: string;
  @IsOptional() @IsArray() @IsString({ each: true }) diagnosticos?: string[];
}

export class ReportarProblemaDto {
  @IsString() @IsNotEmpty() @MaxLength(1000) motivo: string;
}

export class FiltrosCitasDto {
  @IsOptional() @IsMongoId() pacienteId?: string;
  /** Lista separada por comas, p. ej. CONFIRMADA,PENDIENTE_ACEPTACION. */
  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.split(',') : value))
  @IsEnum(EstadoCita, { each: true })
  estados?: EstadoCita[];
  @IsOptional() @IsDateString() desde?: string;
  @IsOptional() @IsDateString() hasta?: string;
}

export const codigoCita = (id: string): string => `BW-${parseInt(id.slice(-6), 16).toString().slice(-5).padStart(5, '0')}`;

export const aCitaRespuesta = (
  c: Cita,
  ctx: { medicos: Map<string, Medico>; pacientes: Map<string, PerfilPaciente>; pagos: Map<string, Pago> },
) => {
  const medico = ctx.medicos.get(c.medicoId);
  const paciente = ctx.pacientes.get(c.pacienteId);
  const pago = ctx.pagos.get(c.id);
  return {
    id: c.id,
    codigo: codigoCita(c.id),
    estado: c.estado,
    inicio: c.inicio,
    fin: c.fin,
    modalidad: c.modalidad,
    motivo: c.motivo,
    monto: aMonto(c.monto),
    moneda: c.moneda,
    paciente: paciente ? { id: paciente.id, nombreCompleto: paciente.nombreCompleto, parentesco: paciente.parentescoConTitular } : { id: c.pacienteId },
    medico: medico
      ? {
          id: medico.id,
          nombreCompleto: medico.nombreCompleto,
          especialidad: medico.especialidades[0],
          direccionConsultorio: medico.direccionConsultorio,
          zonaHorariaMin: medico.zonaHorariaMin,
        }
      : { id: c.medicoId },
    politicaCancelacion: {
      tipo: c.politicaAplicada.tipo,
      horasMinimasAviso: c.politicaAplicada.horasMinimasAviso,
      porcentajePenalizacion: c.politicaAplicada.porcentajePenalizacion,
      descripcion: c.politicaAplicada.descripcion,
    },
    citaOrigenId: c.citaOrigenId,
    referenciaId: c.referenciaId,
    propuestaPor: c.propuestaPor,
    propuestaExpiraEn: c.propuestaExpiraEn,
    parteQueDebeResponder: c.parteQueDebeResponder,
    canceladaPor: c.canceladaPor,
    motivoCancelacion: c.motivoCancelacion,
    atendidaEn: c.atendidaEn,
    creadaEn: c.creadaEn,
    pago: pago ? aPagoRespuesta(pago) : undefined,
  };
};
