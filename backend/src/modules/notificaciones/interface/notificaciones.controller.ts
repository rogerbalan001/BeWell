import { Body, Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor } from '../../../shared/domain/roles';
import { ActorActual } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { IsNotEmpty, IsString, IsUrl, MaxLength } from 'class-validator';
import { NotificacionesService } from '../application/notificaciones.service';
import { PushService } from '../application/push.service';

class SuscripcionPushDto {
  @IsUrl({ protocols: ['https'], require_tld: false }) @MaxLength(1000) endpoint: string;
  @IsString() @IsNotEmpty() @MaxLength(200) p256dh: string;
  @IsString() @IsNotEmpty() @MaxLength(100) auth: string;
}

class BajaPushDto {
  @IsString() @IsNotEmpty() @MaxLength(1000) endpoint: string;
}

@ApiTags('Notificaciones')
@ApiBearerAuth()
@Controller('notificaciones')
export class NotificacionesController {
  constructor(
    private readonly notificaciones: NotificacionesService,
    private readonly push: PushService,
  ) {}

  /** Clave pública VAPID con la que el navegador del teléfono se suscribe a las notificaciones. */
  @Get('push/clave')
  async clavePush(): Promise<{ clavePublica: string }> {
    return { clavePublica: await this.push.clavePublica() };
  }

  @HttpCode(204)
  @Post('push/suscripcion')
  suscribir(@ActorActual() actor: Actor, @Body() dto: SuscripcionPushDto): Promise<void> {
    return this.push.suscribir(actor.id, { endpoint: dto.endpoint, p256dh: dto.p256dh, auth: dto.auth });
  }

  @HttpCode(204)
  @Post('push/baja')
  darDeBaja(@Body() dto: BajaPushDto): Promise<void> {
    return this.push.darDeBaja(dto.endpoint);
  }

  /** Manda un aviso de prueba al teléfono para confirmar que las notificaciones llegan. */
  @Post('push/prueba')
  async probar(@ActorActual() actor: Actor): Promise<{ enviadas: number }> {
    const enviadas = await this.push.enviar({
      usuarioId: actor.id,
      tipo: 'RECORDATORIO',
      titulo: 'Notificaciones activadas',
      mensaje: 'Así te llegarán tus recordatorios de BeWell, aunque no tengas la app abierta.',
    });
    return { enviadas };
  }

  @Get()
  async listar(@ActorActual() actor: Actor) {
    const [items, noLeidas] = await Promise.all([
      this.notificaciones.listar(actor.id),
      this.notificaciones.contarNoLeidas(actor.id),
    ]);
    return {
      noLeidas,
      items: items.map((n) => ({ id: n.id, tipo: n.tipo, titulo: n.titulo, mensaje: n.mensaje, datos: n.datos, leida: n.leida, creadaEn: n.creadaEn })),
    };
  }

  @HttpCode(204)
  @Post('leer-todas')
  marcarTodas(@ActorActual() actor: Actor): Promise<void> {
    return this.notificaciones.marcarTodasLeidas(actor.id);
  }

  @HttpCode(204)
  @Post(':id/leida')
  marcarLeida(@ActorActual() actor: Actor, @Param('id', ParseObjectIdPipe) id: string): Promise<void> {
    return this.notificaciones.marcarLeida(actor.id, id);
  }
}
