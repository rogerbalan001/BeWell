import { Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Actor } from '../../../shared/domain/roles';
import { ActorActual } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { NotificacionesService } from '../application/notificaciones.service';

@ApiTags('Notificaciones')
@ApiBearerAuth()
@Controller('notificaciones')
export class NotificacionesController {
  constructor(private readonly notificaciones: NotificacionesService) {}

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
