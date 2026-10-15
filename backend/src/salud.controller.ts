import { Controller, Get } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { ApiTags } from '@nestjs/swagger';
import { Connection } from 'mongoose';
import { Publico } from './shared/interface/auth/decoradores';

/** Health checks de vida y disponibilidad para el balanceador. */
@ApiTags('Salud')
@Controller('salud')
export class SaludController {
  constructor(@InjectConnection() private readonly conexion: Connection) {}

  @Publico()
  @Get('vida')
  vida() {
    return { estado: 'ok' };
  }

  @Publico()
  @Get('disponibilidad')
  disponibilidad() {
    const mongo = this.conexion.readyState === 1 ? 'ok' : 'caido';
    return { estado: mongo === 'ok' ? 'ok' : 'degradado', mongo };
  }
}
