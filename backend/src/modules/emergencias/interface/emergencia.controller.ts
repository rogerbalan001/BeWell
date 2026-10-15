import { Body, Controller, Get, Ip, Param, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Type } from 'class-transformer';
import { IsArray, IsIn, IsNotEmpty, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, AuthOpcional, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { EmergenciaService } from '../application/emergencia.service';
import { CAMPOS_FICHA, CampoFicha, FichaEmergencia, GRUPOS_SANGUINEOS } from '../domain/ficha-emergencia';

export class ContactoDto {
  @IsString() @IsNotEmpty() @MaxLength(80) nombre: string;
  @IsOptional() @IsString() @MaxLength(40) parentesco: string;
  @IsString() @IsNotEmpty() @MaxLength(25) telefono: string;
}

export class FichaDto {
  @IsOptional() @IsIn(GRUPOS_SANGUINEOS) grupoSanguineo?: string;
  @IsArray() @IsString({ each: true }) alergias: string[];
  @IsArray() @IsString({ each: true }) condicionesCronicas: string[];
  @IsArray() @IsString({ each: true }) medicacionActual: string[];
  @IsArray() @ValidateNested({ each: true }) @Type(() => ContactoDto) contactos: ContactoDto[];
  @IsArray() @IsIn(CAMPOS_FICHA, { each: true }) camposPublicos: CampoFicha[];
}

const aFichaRespuesta = (f: FichaEmergencia) => ({
  pacienteId: f.pacienteId,
  grupoSanguineo: f.grupoSanguineo,
  alergias: f.alergias,
  condicionesCronicas: f.condicionesCronicas,
  medicacionActual: f.medicacionActual,
  contactos: f.contactos,
  camposPublicos: f.camposPublicos,
  tieneQr: !!f.tokenQrHash,
  qrGeneradoEn: f.qrGeneradoEn,
  actualizadoEn: f.actualizadoEn,
});

/** «Boundary» EmergenciaController. */
@ApiTags('Emergencias QR')
@Controller('emergencia')
export class EmergenciaController {
  constructor(private readonly emergencia: EmergenciaService) {}

  /**
   * Ruta crítica (p95 < 200 ms): pública, con límite de tasa por IP para
   * impedir la enumeración de tokens. Con token de PERSONAL_EMERGENCIA
   * devuelve la ficha ampliada.
   */
  @AuthOpcional()
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  @Get('qr/:token')
  obtenerFicha(@Param('token') token: string, @ActorActual() actor: Actor | undefined, @Ip() ip: string) {
    return this.emergencia.obtenerFichaPorToken(token, actor, ip);
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Get('fichas/:pacienteId')
  async ficha(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    return aFichaRespuesta(await this.emergencia.obtenerFicha(actor, pacienteId));
  }

  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Put('fichas/:pacienteId')
  async actualizarFicha(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string, @Body() dto: FichaDto) {
    return aFichaRespuesta(
      await this.emergencia.actualizarFicha(actor, pacienteId, {
        ...dto,
        contactos: dto.contactos.map((c) => ({ ...c, parentesco: c.parentesco ?? '' })),
      }),
    );
  }

  /** Devuelve el token en claro UNA sola vez; el servidor guarda solo su hash. */
  @ApiBearerAuth()
  @Roles(RolUsuario.PACIENTE)
  @Post('fichas/:pacienteId/qr')
  regenerarQr(@ActorActual() actor: Actor, @Param('pacienteId', ParseObjectIdPipe) pacienteId: string) {
    return this.emergencia.regenerarQr(actor, pacienteId);
  }
}
