import { IsDateString, IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { DatosPersonales, PerfilPaciente, Sexo } from '../../domain/perfil-paciente';

export class DatosPersonalesDto {
  @IsString() @IsNotEmpty() @MaxLength(80) nombres: string;
  @IsString() @IsNotEmpty() @MaxLength(80) apellidos: string;
  /** Opcional para menores de edad. */
  @IsOptional() @IsString() @MaxLength(20) cedula?: string;
  /** ISO 8601 (AAAA-MM-DD). */
  @IsDateString() fechaNacimiento: string;
  @IsIn(['F', 'M', 'OTRO']) sexo: Sexo;

  aDominio(): DatosPersonales {
    return {
      nombres: this.nombres,
      apellidos: this.apellidos,
      cedula: this.cedula,
      fechaNacimiento: new Date(this.fechaNacimiento),
      sexo: this.sexo,
    };
  }
}

export class CrearPerfilFamiliarDto extends DatosPersonalesDto {
  /** Ej.: HIJO, HIJA, MADRE, PADRE, CONYUGE. */
  @IsString() @IsNotEmpty() @MaxLength(30) parentescoConTitular: string;
}

export class ActualizarPerfilDto {
  @IsOptional() @IsString() @IsNotEmpty() nombres?: string;
  @IsOptional() @IsString() @IsNotEmpty() apellidos?: string;
  @IsOptional() @IsString() cedula?: string;
  @IsOptional() @IsDateString() fechaNacimiento?: string;
  @IsOptional() @IsIn(['F', 'M', 'OTRO']) sexo?: Sexo;
}

export interface PerfilRespuesta {
  id: string;
  titularUsuarioId: string;
  parentescoConTitular: string;
  esTitular: boolean;
  nombres: string;
  apellidos: string;
  nombreCompleto: string;
  cedula?: string;
  fechaNacimiento: string;
  edad: number;
  sexo: Sexo;
}

export const aPerfilRespuesta = (p: PerfilPaciente, ahora = new Date()): PerfilRespuesta => ({
  id: p.id,
  titularUsuarioId: p.titularUsuarioId,
  parentescoConTitular: p.parentescoConTitular,
  esTitular: p.esTitular,
  nombres: p.nombres,
  apellidos: p.apellidos,
  nombreCompleto: p.nombreCompleto,
  cedula: p.cedula,
  fechaNacimiento: p.fechaNacimiento.toISOString().slice(0, 10),
  edad: p.edad(ahora),
  sexo: p.sexo,
});
