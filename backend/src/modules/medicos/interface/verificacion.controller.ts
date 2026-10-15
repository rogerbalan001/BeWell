import { Body, Controller, Get, Param, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ArchivoSubido, validarArchivo } from '../../../shared/interface/http/archivo-subido';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { VerificacionProfesionalService } from '../application/verificacion-profesional.service';
import { aMedicoCompleto, RechazarCredencialDto, RegistrarCredencialDto } from './dto/medico.dto';

/** «Boundary» HU: validar título, colegiatura y cédula de cada médico. */
@ApiTags('Verificación profesional')
@ApiBearerAuth()
@Controller('verificaciones')
export class VerificacionController {
  constructor(private readonly verificacion: VerificacionProfesionalService) {}

  /** El médico carga una credencial (multipart: tipo, numero, archivo). */
  @Roles(RolUsuario.MEDICO)
  @Post('credenciales')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('archivo', { limits: { fileSize: 10 * 1024 * 1024 } }))
  async enviarCredenciales(
    @ActorActual() actor: Actor,
    @Body() dto: RegistrarCredencialDto,
    @UploadedFile() archivo: ArchivoSubido,
  ) {
    const valido = validarArchivo(archivo);
    const credencial = await this.verificacion.registrarCredencial(actor, dto.tipo, dto.numero, {
      contenido: valido.buffer,
      tipoMime: valido.mimetype,
      nombreOriginal: valido.originalname,
    });
    return { id: credencial.id, tipo: credencial.tipo, numero: credencial.numero, estado: credencial.estado };
  }

  @Roles(RolUsuario.ADMIN)
  @Get('pendientes')
  async listarPendientes() {
    return (await this.verificacion.listarPendientes()).map(aMedicoCompleto);
  }

  @Roles(RolUsuario.ADMIN)
  @Post(':medicoId/credenciales/:credencialId/aprobar')
  async aprobar(
    @ActorActual() admin: Actor,
    @Param('medicoId', ParseObjectIdPipe) medicoId: string,
    @Param('credencialId', ParseObjectIdPipe) credencialId: string,
  ) {
    return aMedicoCompleto(await this.verificacion.aprobarCredencial(admin.id, medicoId, credencialId));
  }

  @Roles(RolUsuario.ADMIN)
  @Post(':medicoId/credenciales/:credencialId/rechazar')
  async rechazar(
    @ActorActual() admin: Actor,
    @Param('medicoId', ParseObjectIdPipe) medicoId: string,
    @Param('credencialId', ParseObjectIdPipe) credencialId: string,
    @Body() dto: RechazarCredencialDto,
  ) {
    return aMedicoCompleto(await this.verificacion.rechazarCredencial(admin.id, medicoId, credencialId, dto.motivo));
  }

  /** URL temporal para que el administrador revise el documento. */
  @Roles(RolUsuario.ADMIN)
  @Get(':medicoId/credenciales/:credencialId/archivo')
  async archivo(
    @Param('medicoId', ParseObjectIdPipe) medicoId: string,
    @Param('credencialId', ParseObjectIdPipe) credencialId: string,
  ) {
    return { url: await this.verificacion.urlArchivo(medicoId, credencialId) };
  }
}
