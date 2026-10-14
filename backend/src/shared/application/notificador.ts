/**
 * Puerto para avisar a un usuario. El módulo Notificaciones lo implementa
 * (bandeja in-app en el MVP; FCM/APNs/correo en sprints posteriores).
 */
export interface NuevaNotificacion {
  usuarioId: string;
  tipo: string;
  titulo: string;
  mensaje: string;
  datos?: Record<string, string>;
}

export abstract class Notificador {
  abstract notificar(notificacion: NuevaNotificacion): Promise<void>;
}
