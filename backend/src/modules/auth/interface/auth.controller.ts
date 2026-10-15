import { Body, Controller, Get, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { aCentavos } from '../../../shared/domain/dinero';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Publico } from '../../../shared/interface/auth/decoradores';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { aPerfilRespuesta } from '../../perfiles/interface/dto/perfil.dto';
import { AuthService, Sesion } from '../application/auth.service';
import { LoginDto, RefreshDto, RegistroMedicoDto, RegistroPacienteDto } from './dto/auth.dto';

/** «Boundary» AuthController: registro, inicio de sesión, renovación y cierre. */
@ApiTags('Autenticación')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
  ) {}

  @Publico()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('registro/paciente')
  registrarPaciente(@Body() dto: RegistroPacienteDto): Promise<Sesion> {
    return this.auth.registrarPaciente({ ...dto.aDominio(), email: dto.email, password: dto.password, telefono: dto.telefono });
  }

  @Publico()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('registro/medico')
  registrarMedico(@Body() dto: RegistroMedicoDto): Promise<Sesion> {
    return this.auth.registrarMedico({ ...dto, tarifaConsulta: aCentavos(dto.tarifaConsulta) });
  }

  @Publico()
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @HttpCode(200)
  @Post('login')
  iniciarSesion(@Body() dto: LoginDto): Promise<Sesion> {
    return this.auth.iniciarSesion(dto.email, dto.password);
  }

  @Publico()
  @HttpCode(200)
  @Post('refresh')
  refrescar(@Body() dto: RefreshDto): Promise<Sesion> {
    return this.auth.refrescar(dto.refreshToken);
  }

  @ApiBearerAuth()
  @HttpCode(204)
  @Post('logout')
  cerrarSesion(@ActorActual() actor: Actor): Promise<void> {
    return this.auth.cerrarSesion(actor.id);
  }

  /** Usuario autenticado con sus perfiles de paciente o su ficha de médico. */
  @ApiBearerAuth()
  @Get('yo')
  async yo(@ActorActual() actor: Actor) {
    const usuario = await this.auth.obtenerUsuario(actor.id);
    const perfiles = usuario.roles.includes(RolUsuario.PACIENTE) ? await this.perfiles.listarPerfiles(usuario.id) : [];
    const medico = actor.medicoId ? await this.medicos.obtener(actor.medicoId) : null;
    return {
      id: usuario.id,
      email: usuario.email,
      roles: usuario.roles,
      nombreMostrado: usuario.nombreMostrado,
      telefono: usuario.telefono,
      medicoId: medico?.id,
      estadoVerificacionMedico: medico?.estadoVerificacion,
      perfiles: perfiles.map((p) => aPerfilRespuesta(p)),
    };
  }
}
