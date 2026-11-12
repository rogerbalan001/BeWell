import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

/** Longitud máxima de un mensaje del chat médico-paciente. */
export const LONGITUD_MAXIMA_MENSAJE = 2000;

/** Parte de la cita que escribe el mensaje. */
export type AutorChat = 'PACIENTE' | 'MEDICO';

export interface PropsMensajeChat {
  id: string;
  citaId: string;
  autor: AutorChat;
  autorUsuarioId: string;
  /** Usuario que recibe el mensaje (titular del perfil o médico): sirve para contar los no leídos. */
  destinatarioUsuarioId: string;
  texto: string;
  enviadoEn: Date;
  leidoEn?: Date;
}

/**
 * «Entity» Mensaje del chat privado de una cita. Solo existe dentro de una
 * cita, y solo el paciente (o su titular) y el médico de esa cita lo ven.
 */
export class MensajeChat implements PropsMensajeChat {
  id: string;
  citaId: string;
  autor: AutorChat;
  autorUsuarioId: string;
  destinatarioUsuarioId: string;
  texto: string;
  enviadoEn: Date;
  leidoEn?: Date;

  constructor(props: PropsMensajeChat) {
    Object.assign(this, props);
  }

  /** Crea un mensaje nuevo; rechaza los vacíos y los demasiado largos. */
  static escribir(datos: Omit<PropsMensajeChat, 'id' | 'enviadoEn' | 'leidoEn'>, ahora: Date): MensajeChat {
    const texto = (datos.texto ?? '').trim();
    asegurar(texto.length > 0, 'El mensaje no puede estar vacío');
    asegurar(texto.length <= LONGITUD_MAXIMA_MENSAJE, `El mensaje no puede superar ${LONGITUD_MAXIMA_MENSAJE} caracteres`);
    return new MensajeChat({ ...datos, texto, id: generarId(), enviadoEn: ahora });
  }

  get leido(): boolean {
    return !!this.leidoEn;
  }
}
