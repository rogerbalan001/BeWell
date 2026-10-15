import { ArrayNotEmpty, IsArray, IsEmail, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min, MinLength } from 'class-validator';
import { DatosPersonalesDto } from '../../../perfiles/interface/dto/perfil.dto';

export class RegistroPacienteDto extends DatosPersonalesDto {
  @IsEmail() email: string;
  /** Mínimo 8 caracteres, con letras y números. */
  @IsString() @MinLength(8) @MaxLength(72) password: string;
  @IsOptional() @IsString() @MaxLength(20) telefono?: string;
}

export class RegistroMedicoDto {
  @IsEmail() email: string;
  @IsString() @MinLength(8) @MaxLength(72) password: string;
  @IsOptional() @IsString() @MaxLength(20) telefono?: string;
  @IsString() @IsNotEmpty() @MaxLength(80) nombres: string;
  @IsString() @IsNotEmpty() @MaxLength(80) apellidos: string;
  @IsArray() @ArrayNotEmpty() @IsString({ each: true }) especialidades: string[];
  /** Tarifa en USD. */
  @IsNumber() @Min(1) tarifaConsulta: number;
}

export class LoginDto {
  @IsEmail() email: string;
  @IsString() @IsNotEmpty() password: string;
}

export class RefreshDto {
  @IsString() @IsNotEmpty() refreshToken: string;
}
