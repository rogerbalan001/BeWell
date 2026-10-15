import { generarId } from '../../../shared/domain/id';
import { NuevaNotificacion } from '../../../shared/application/notificador';

/** «Entity» Notificacion de la bandeja in-app. */
export class Notificacion {
  constructor(
    readonly id: string,
    readonly usuarioId: string,
    readonly tipo: string,
    readonly titulo: string,
    readonly mensaje: string,
    readonly datos: Record<string, string>,
    public leida: boolean,
    readonly creadaEn: Date,
  ) {}

  static crear(n: NuevaNotificacion, ahora: Date): Notificacion {
    return new Notificacion(generarId(), n.usuarioId, n.tipo, n.titulo, n.mensaje, n.datos ?? {}, false, ahora);
  }
}

export abstract class NotificacionRepository {
  abstract guardar(n: Notificacion): Promise<void>;
  abstract listarPorUsuario(usuarioId: string, limite: number): Promise<Notificacion[]>;
  abstract marcarLeida(usuarioId: string, id: string): Promise<void>;
  abstract marcarTodasLeidas(usuarioId: string): Promise<void>;
  abstract contarNoLeidas(usuarioId: string): Promise<number>;
}
