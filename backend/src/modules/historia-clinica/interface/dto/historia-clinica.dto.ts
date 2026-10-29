import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { Medico } from '../../../medicos/domain/medico';
import { HistoriaClinicaVista } from '../../application/historia-clinica.service';
import { AntecedentesClinicos, GRUPOS_SANGUINEOS, GrupoSanguineo } from '../../domain/antecedentes-clinicos';
import { ConsultaClinica } from '../../domain/consulta-clinica';
import { aPerfilRespuesta } from '../../../perfiles/interface/dto/perfil.dto';

export class GinecoObstetricosDto {
  @IsOptional() @IsString() @MaxLength(300) menarquia?: string;
  @IsOptional() @IsString() @MaxLength(300) ultimaMenstruacion?: string;
  @IsOptional() @IsInt() @Min(0) @Max(30) gestas?: number;
  @IsOptional() @IsInt() @Min(0) @Max(30) partos?: number;
  @IsOptional() @IsInt() @Min(0) @Max(30) cesareas?: number;
  @IsOptional() @IsInt() @Min(0) @Max(30) abortos?: number;
  @IsOptional() @IsInt() @Min(0) @Max(30) perdidasFetales?: number;
  @IsOptional() @IsString() @MaxLength(300) eclampsia?: string;
  @IsOptional() @IsString() @MaxLength(300) menopausia?: string;
  @IsOptional() @IsString() @MaxLength(300) trastornosMenstruales?: string;
  @IsOptional() @IsString() @MaxLength(300) metodoAnticonceptivo?: string;
}

/** Los campos de texto por clave (identificación, hábitos, familiares…) los valida el dominio contra el catálogo. */
export class AntecedentesClinicosDto {
  @IsOptional() @IsIn(GRUPOS_SANGUINEOS) grupoSanguineo?: GrupoSanguineo;
  @IsOptional() @IsObject() datosSociales?: Record<string, string>;
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) inmunizaciones?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) infancia?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) alergicos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) parasitosis?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) infecciones?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) transmisionSexual?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) epidemiologicos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) patologicos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) quirurgicos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) traumatologicos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) psiquiatricos?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) laborales?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) intoxicaciones?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) radiaciones?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) transfusionales?: string[];
  @IsOptional() @IsArray() @ArrayMaxSize(50) @IsString({ each: true }) @MaxLength(300, { each: true }) medicamentosActuales?: string[];
  @IsOptional() @IsObject() familiares?: Record<string, string[]>;
  @IsOptional() @IsObject() habitos?: Record<string, string>;
  @IsOptional() @ValidateNested() @Type(() => GinecoObstetricosDto) ginecoObstetricos?: GinecoObstetricosDto;
}

export class SignosVitalesDto {
  @IsOptional() @IsString() @MaxLength(9) tensionArterial?: string;
  @IsOptional() @IsString() @MaxLength(9) tensionArterialAcostado?: string;
  @IsOptional() @IsString() @MaxLength(9) tensionArterialDePie?: string;
  @IsOptional() @IsNumber() frecuenciaCardiaca?: number;
  @IsOptional() @IsNumber() frecuenciaRespiratoria?: number;
  @IsOptional() @IsNumber() temperatura?: number;
  @IsOptional() @IsNumber() saturacionOxigeno?: number;
  @IsOptional() @IsNumber() peso?: number;
  @IsOptional() @IsNumber() talla?: number;
  @IsOptional() @IsNumber() circunferenciaAbdominal?: number;
}

export class ContenidoConsultaDto {
  @IsString() @IsNotEmpty() @MaxLength(5000) motivoConsulta: string;
  @IsOptional() @IsString() @MaxLength(5000) estimuloIatrotropico?: string;
  @IsString() @IsNotEmpty() @MaxLength(5000) enfermedadActual: string;
  @IsOptional() @IsObject() revisionSistemas?: Record<string, string>;
  @IsOptional() @IsString() @MaxLength(5000) revisionPorSistemas?: string;
  @IsOptional() @IsString() @MaxLength(5000) condicionesGenerales?: string;
  @IsOptional() @ValidateNested() @Type(() => SignosVitalesDto) signosVitales?: SignosVitalesDto;
  @IsOptional() @IsObject() examenRegiones?: Record<string, string>;
  @IsOptional() @IsString() @MaxLength(5000) examenFisico?: string;
  @IsOptional() @IsString() @MaxLength(5000) resumenDatosPositivos?: string;
  @IsOptional() @IsArray() @ArrayMaxSize(15) @IsString({ each: true }) @MaxLength(300, { each: true }) listaProblemas?: string[];
  @IsOptional() @IsBoolean() consentimientoInformado?: boolean;
  @IsArray() @ArrayNotEmpty() @ArrayMaxSize(15) @IsString({ each: true }) @MaxLength(300, { each: true }) impresionDiagnostica: string[];
  @IsOptional() @IsObject() examenes?: Record<string, string>;
  @IsOptional() @IsString() @MaxLength(5000) planDiagnostico?: string;
  @IsOptional() @IsString() @MaxLength(5000) planPreventivo?: string;
  @IsOptional() @IsString() @MaxLength(5000) plan?: string;
  @IsOptional() @IsString() @MaxLength(5000) indicaciones?: string;
}

export class NuevaConsultaDto extends ContenidoConsultaDto {
  @IsOptional() @IsMongoId() citaId?: string;
  @IsOptional() @IsDateString() fecha?: string;
}

const aMedicoResumen = (m?: Medico) =>
  m ? { id: m.id, nombreCompleto: m.nombreCompleto, especialidad: m.especialidades[0], verificado: m.estaVerificado() } : undefined;

export const aAntecedentesRespuesta = (a: AntecedentesClinicos) => ({
  id: a.id,
  numeroHistoria: `HC-${a.id.slice(-6).toUpperCase()}`,
  ...a.datos,
  actualizadoEn: a.actualizadoEn,
  actualizadoPorMedico: !!a.actualizadoPorMedicoId,
});

export const aConsultaRespuesta = (c: ConsultaClinica, medicos: Map<string, Medico>, actorMedicoId?: string, ahora = new Date()) => ({
  id: c.id,
  pacienteId: c.pacienteId,
  citaId: c.citaId,
  fecha: c.fecha,
  medico: aMedicoResumen(medicos.get(c.medicoId)),
  ...c.contenido(),
  imc: c.imc,
  editable: c.puedeEditar(actorMedicoId, ahora),
  creadaEn: c.creadaEn,
  actualizadaEn: c.actualizadaEn,
});

export const aHistoriaRespuesta = (v: HistoriaClinicaVista, medicos: Map<string, Medico>, actorMedicoId?: string) => ({
  paciente: aPerfilRespuesta(v.paciente),
  acceso: v.acceso,
  antecedentes: v.antecedentes ? aAntecedentesRespuesta(v.antecedentes) : null,
  consultas: v.consultas.map((c) => aConsultaRespuesta(c, medicos, actorMedicoId)),
  puedeEditarAntecedentes: v.puedeEditarAntecedentes,
  puedeRegistrarConsulta: v.puedeRegistrarConsulta,
});
