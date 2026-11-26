import { Injectable, Logger, Optional } from '@nestjs/common';
import { NuevaNotificacion, Notificador } from '../../../shared/application/notificador';
import { Reloj } from '../../../shared/domain/reloj';
import { Notificacion, NotificacionRepository } from '../domain/notificacion';
import { PushService } from './push.service';

/**
 * «Control» Notificaciones. Guarda la notificación en la bandeja in-app y la
 * envía como push a los teléfonos del usuario que autorizaron las notificaciones.
 */
@Injectable()
export class NotificacionesService extends Notificador {
  private readonly logger = new Logger(NotificacionesService.name);

  constructor(
    private readonly repositorio: NotificacionRepository,
    private readonly reloj: Reloj,
    @Optional() private readonly push?: PushService,
  ) {
    super();
  }

  async notificar(n: NuevaNotificacion): Promise<void> {
    try {
      await this.repositorio.guardar(Notificacion.crear(n, this.reloj.ahora()));
    } catch (e) {
      this.logger.warn(`No se pudo guardar la notificación: ${(e as Error).message}`);
    }
    // También al teléfono, sin hacer esperar a quien originó el aviso.
    void this.push?.enviar(n).catch((e: Error) => this.logger.warn(`Push no enviado: ${e.message}`));
  }

  listar(usuarioId: string): Promise<Notificacion[]> {
    return this.repositorio.listarPorUsuario(usuarioId, 50);
  }

  contarNoLeidas(usuarioId: string): Promise<number> {
    return this.repositorio.contarNoLeidas(usuarioId);
  }

  marcarLeida(usuarioId: string, id: string): Promise<void> {
    return this.repositorio.marcarLeida(usuarioId, id);
  }

  marcarTodasLeidas(usuarioId: string): Promise<void> {
    return this.repositorio.marcarTodasLeidas(usuarioId);
  }
}
