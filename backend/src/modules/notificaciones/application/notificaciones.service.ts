import { Injectable, Logger } from '@nestjs/common';
import { NuevaNotificacion, Notificador } from '../../../shared/application/notificador';
import { Reloj } from '../../../shared/domain/reloj';
import { Notificacion, NotificacionRepository } from '../domain/notificacion';

/**
 * «Control» Notificaciones. En el MVP guarda la notificación en la bandeja
 * in-app; el envío push/correo se delega a un worker en sprints posteriores.
 */
@Injectable()
export class NotificacionesService extends Notificador {
  private readonly logger = new Logger(NotificacionesService.name);

  constructor(
    private readonly repositorio: NotificacionRepository,
    private readonly reloj: Reloj,
  ) {
    super();
  }

  async notificar(n: NuevaNotificacion): Promise<void> {
    try {
      await this.repositorio.guardar(Notificacion.crear(n, this.reloj.ahora()));
    } catch (e) {
      this.logger.warn(`No se pudo guardar la notificación: ${(e as Error).message}`);
    }
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
