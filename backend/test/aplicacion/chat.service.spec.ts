import { AccesoDenegadoError, ReglaNegocioError } from '../../src/shared/domain/errores';
import { ChatService } from '../../src/modules/chat/application/chat.service';
import { MensajeChat } from '../../src/modules/chat/domain/mensaje-chat';
import { MensajeChatRepository, NoLeidosPorCita } from '../../src/modules/chat/domain/mensaje-chat.repository';
import { crearContexto } from '../support/contexto';

/** Lunes 12/10/2026 09:00 en Caracas. */
const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');

class MensajesMemoria extends MensajeChatRepository {
  datos: MensajeChat[] = [];
  async guardar(m: MensajeChat) {
    this.datos = [...this.datos.filter((x) => x.id !== m.id), new MensajeChat({ ...m })];
  }
  async listarPorCita(citaId: string, despuesDe?: Date) {
    return this.datos
      .filter((m) => m.citaId === citaId && (!despuesDe || m.enviadoEn > despuesDe))
      .sort((a, b) => a.enviadoEn.getTime() - b.enviadoEn.getTime());
  }
  async marcarLeidos(citaId: string, usuarioId: string, ahora: Date) {
    const pendientes = this.datos.filter((m) => m.citaId === citaId && m.destinatarioUsuarioId === usuarioId && !m.leidoEn);
    pendientes.forEach((m) => (m.leidoEn = ahora));
    return pendientes.length;
  }
  async contarNoLeidos(usuarioId: string): Promise<NoLeidosPorCita[]> {
    const mapa = new Map<string, number>();
    for (const m of this.datos.filter((x) => x.destinatarioUsuarioId === usuarioId && !x.leidoEn)) mapa.set(m.citaId, (mapa.get(m.citaId) ?? 0) + 1);
    return [...mapa].map(([citaId, noLeidos]) => ({ citaId, noLeidos }));
  }
}

async function escenario() {
  const ctx = crearContexto();
  const medico = await ctx.medicoVerificado('Mateo');
  const paciente = await ctx.pacienteTitular();
  const cita = await ctx.citas.agendar(paciente.actor, { medicoId: medico.medicoId!, pacienteId: paciente.perfil.id, inicio: NUEVE_AM, modalidad: 'VIRTUAL', motivo: 'Control' });
  const repo = new MensajesMemoria();
  const chat = new ChatService(repo, ctx.citas, ctx.perfiles, ctx.medicos, ctx.notificador, ctx.reloj);
  return { ctx, medico, paciente, cita, repo, chat };
}

describe('ChatService — chat privado de la cita', () => {
  it('el paciente y el médico de una cita confirmada conversan en orden', async () => {
    const { ctx, medico, paciente, cita, chat } = await escenario();
    await chat.enviar(paciente.actor, cita.id, '¿Debo llevar mis exámenes?');
    ctx.reloj.avanzarHoras(0.1);
    await chat.enviar(medico, cita.id, 'Sí, los del último mes.');
    const vistaPaciente = await chat.conversacion(paciente.actor, cita.id);
    expect(vistaPaciente.habilitado).toBe(true);
    expect(vistaPaciente.miParte).toBe('PACIENTE');
    expect(vistaPaciente.mensajes.map((m) => [m.autor, m.texto])).toEqual([
      ['PACIENTE', '¿Debo llevar mis exámenes?'],
      ['MEDICO', 'Sí, los del último mes.'],
    ]);
    expect((await chat.conversacion(medico, cita.id)).miParte).toBe('MEDICO');
  });

  it('con "despuesDe" devuelve solo los mensajes nuevos (actualización cada 5 s)', async () => {
    const { ctx, medico, paciente, cita, chat } = await escenario();
    const primero = await chat.enviar(paciente.actor, cita.id, 'Hola');
    ctx.reloj.avanzarHoras(0.01);
    await chat.enviar(medico, cita.id, 'Buenos días');
    const nuevos = await chat.conversacion(paciente.actor, cita.id, primero.enviadoEn);
    expect(nuevos.mensajes.map((m) => m.texto)).toEqual(['Buenos días']);
  });

  it('avisa a la otra parte con una notificación del chat', async () => {
    const { ctx, medico, paciente, cita, chat } = await escenario();
    await chat.enviar(paciente.actor, cita.id, '¿Puedo tomar ibuprofeno?');
    const aviso = ctx.notificador.enviadas.find((n) => n.tipo === 'CHAT');
    expect(aviso).toMatchObject({ usuarioId: medico.id, titulo: 'Nuevo mensaje de tu paciente', datos: { citaId: cita.id } });
    await chat.enviar(medico, cita.id, 'Sí, cada 8 horas.');
    expect(ctx.notificador.enviadas.some((n) => n.tipo === 'CHAT' && n.usuarioId === paciente.actor.id)).toBe(true);
  });

  it('cuenta los no leídos de quien recibe y los marca como leídos', async () => {
    const { medico, paciente, cita, chat } = await escenario();
    await chat.enviar(paciente.actor, cita.id, 'Uno');
    await chat.enviar(paciente.actor, cita.id, 'Dos');
    expect(await chat.noLeidos(medico)).toEqual([{ citaId: cita.id, noLeidos: 2 }]);
    expect(await chat.noLeidos(paciente.actor)).toEqual([]);
    expect(await chat.marcarLeidos(medico, cita.id)).toBe(2);
    expect(await chat.noLeidos(medico)).toEqual([]);
  });

  it('rechaza a terceros: otro paciente y otro médico', async () => {
    const { ctx, cita, chat } = await escenario();
    const intruso = await ctx.pacienteTitular('Intruso');
    const otroMedico = await ctx.medicoVerificado('Otro');
    await expect(chat.enviar(intruso.actor, cita.id, 'Hola')).rejects.toThrow(AccesoDenegadoError);
    await expect(chat.conversacion(intruso.actor, cita.id)).rejects.toThrow(AccesoDenegadoError);
    await expect(chat.conversacion(otroMedico, cita.id)).rejects.toThrow(AccesoDenegadoError);
    expect(ctx.notificador.enviadas.some((n) => n.tipo === 'CHAT')).toBe(false);
  });

  it('rechaza mensajes vacíos', async () => {
    const { paciente, cita, chat, repo } = await escenario();
    await expect(chat.enviar(paciente.actor, cita.id, '   ')).rejects.toThrow(ReglaNegocioError);
    expect(repo.datos).toHaveLength(0);
  });

  it('no deja escribir si la cita está cancelada, pero se puede leer el historial', async () => {
    const { paciente, cita, chat, ctx } = await escenario();
    await chat.enviar(paciente.actor, cita.id, 'Antes de cancelar');
    await ctx.citas.cancelar(paciente.actor, cita.id, 'No puedo asistir');
    await expect(chat.enviar(paciente.actor, cita.id, 'Después')).rejects.toThrow('confirmada o atendida');
    const c = await chat.conversacion(paciente.actor, cita.id);
    expect(c.habilitado).toBe(false);
    expect(c.mensajes).toHaveLength(1);
  });

  it('sigue habilitado después de la consulta (cita atendida)', async () => {
    const { ctx, medico, paciente, cita, chat } = await escenario();
    ctx.reloj.avanzarHoras(1.5);
    await ctx.citas.marcarAtendida(medico, cita.id, { notaClinica: 'Bien' });
    expect((await chat.enviar(paciente.actor, cita.id, 'Gracias, doctor')).autor).toBe('PACIENTE');
  });
});
