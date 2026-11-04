import { MensajeChat } from './mensaje-chat';

/** No leídos de un usuario en una cita, para el contador de la app. */
export interface NoLeidosPorCita {
  citaId: string;
  noLeidos: number;
}

/** «Repository» de mensajes del chat (colección `mensajes_chat`). */
export abstract class MensajeChatRepository {
  abstract guardar(mensaje: MensajeChat): Promise<void>;
  /** Mensajes de la cita en orden de envío; con `despuesDe`, solo los posteriores (para actualizar cada 5 s). */
  abstract listarPorCita(citaId: string, despuesDe?: Date, limite?: number): Promise<MensajeChat[]>;
  /** Marca como leídos los mensajes que ese usuario recibió en la cita. Devuelve cuántos cambió. */
  abstract marcarLeidos(citaId: string, destinatarioUsuarioId: string, ahora: Date): Promise<number>;
  abstract contarNoLeidos(destinatarioUsuarioId: string): Promise<NoLeidosPorCita[]>;
}
