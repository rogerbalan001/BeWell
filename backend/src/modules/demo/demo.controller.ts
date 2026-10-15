import { Controller, ForbiddenException, HttpCode, Post } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ModuleRef } from '@nestjs/core';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RolUsuario } from '../../shared/domain/roles';
import { Roles } from '../../shared/interface/auth/decoradores';
import { ResultadoDemo, sembrarDatosDemo } from '../../seed/datos-demo';

/**
 * Solo para el entorno de demostración: reinicia la base de datos con los
 * datos de demo (útil en hosting sin consola). Se habilita con DEMO_REINICIO=true.
 */
@ApiTags('Demo')
@ApiBearerAuth()
@Controller('demo')
export class DemoController {
  constructor(
    private readonly moduleRef: ModuleRef,
    private readonly config: ConfigService,
  ) {}

  @Roles(RolUsuario.ADMIN)
  @HttpCode(200)
  @Post('reiniciar')
  reiniciar(): Promise<ResultadoDemo> {
    if (this.config.get<string>('DEMO_REINICIO') !== 'true') {
      throw new ForbiddenException('El reinicio de datos de demostración está deshabilitado');
    }
    return sembrarDatosDemo(
      (token: unknown) => this.moduleRef.get(token as never, { strict: false }),
      this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:8080/#',
    );
  }
}
