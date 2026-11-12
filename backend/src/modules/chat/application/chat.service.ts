import { Injectable } from '@nestjs/common';
import { Notificador } from '../../../shared/application/notificador';
import { ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { CitasService } from '../../citas/application/citas.service';
import { Cita, EstadoCita } from '../../citas/domain/cita';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { AutorChat, MensajeChat } from '../domain/mensaje-chat';
import { MensajeChatRepository, NoLeidosPorCita } from '../domain/mensaje-chat.repository';

/** Estados de la cita en los que se puede escribir en el chat. */
export const ESTADOS_CON_CHAT = [EstadoCita.CONFIRMADA, EstadoCita.ATENDIDA];

/** Máximo de mensajes por consulta (la app pide solo los nuevos cada 5 s). */
export const LIMITE_MENSAJES = 200;

/** Conversación de una cita vista por quien la consulta. */
export interface ConversacionChat {
  cita: Cita;
  /** Parte del actor en la cita. */
  miParte: AutorChat;
  /** Si todavía se puede escribir (cita confirmada o atendida). */
  habilitado: boolean;
  mensajes: MensajeChat[];
}

/**
 * «Control» ChatService. Chat privado entre el paciente y el médico de una
 * cita. Solo esas dos partes (o el titular que gestiona el perfil del
 * paciente) pueden leerlo; solo se escribe con la cita confirmada o atendida.
 */
@Injectable()
export class ChatService {
  constructor(
    private readonly mensajes: MensajeChatRepository,
    private readonly citas: CitasService,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
  ) {}

  /** Mensajes de la cita en orden; con `despuesDe` devuelve solo los nuevos. Lanza 403 a terceros. */
  async conversacion(actor: Actor, citaId: string, despuesDe?: Date): Promise<ConversacionChat> {
    const cita = await this.citas.obtenerPorId(citaId);
    const miParte = await this.citas.parteDelActor(actor, cita);
    const mensajes = await this.mensajes.listarPorCita(cita.id, despuesDe, LIMITE_MENSAJES);
    return { cita, miParte, habilitado: ESTADOS_CON_CHAT.includes(cita.estado), mensajes };
  }

  /** Envía un mensaje y avisa a la otra parte con una notificación. */
  async enviar(actor: Actor, citaId: string, texto: string): Promise<MensajeChat> {
    const cita = await this.citas.obtenerPorId(citaId);
    const autor = await this.citas.parteDelActor(actor, cita);
    if (!ESTADOS_CON_CHAT.includes(cita.estado)) {
      throw new ReglaNegocioError('El chat se habilita cuando la cita está confirmada o atendida');
    }
    const destinatarioUsuarioId = await this.usuarioDe(autor === 'PACIENTE' ? 'MEDICO' : 'PACIENTE', cita);
    const mensaje = MensajeChat.escribir({ citaId: cita.id, autor, autorUsuarioId: actor.id, destinatarioUsuarioId, texto }, this.reloj.ahora());
    await this.mensajes.guardar(mensaje);
    await this.notificador.notificar({
      usuarioId: destinatarioUsuarioId,
      tipo: 'CHAT',
      titulo: autor === 'MEDICO' ? 'Nuevo mensaje de tu médico' : 'Nuevo mensaje de tu paciente',
      mensaje: mensaje.texto.length > 120 ? `${mensaje.texto.slice(0, 117)}...` : mensaje.texto,
      datos: { citaId: cita.id },
    });
    return mensaje;
  }

  /** Marca como leídos los mensajes que el actor recibió en la cita. */
  async marcarLeidos(actor: Actor, citaId: string): Promise<number> {
    const cita = await this.citas.obtenerPorId(citaId);
    await this.citas.parteDelActor(actor, cita);
    return this.mensajes.marcarLeidos(cita.id, actor.id, this.reloj.ahora());
  }

  /** Mensajes sin leer del actor, por cita, para el contador de la app. */
  noLeidos(actor: Actor): Promise<NoLeidosPorCita[]> {
    return this.mensajes.contarNoLeidos(actor.id);
  }

  /** Usuario que recibe los mensajes de una parte: el titular del perfil del paciente o el médico. */
  private async usuarioDe(parte: AutorChat, cita: Cita): Promise<string> {
    if (parte === 'PACIENTE') return this.perfiles.titularDe(cita.pacienteId);
    return (await this.medicos.obtener(cita.medicoId)).usuarioId;
  }
}
