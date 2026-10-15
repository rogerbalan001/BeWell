import { AccesoDenegadoError, ConflictoError, ReglaNegocioError } from '../../src/shared/domain/errores';
import { EstadoCita } from '../../src/modules/citas/domain/cita';
import { TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { EstadoPago } from '../../src/modules/pagos/domain/pago';
import { crearContexto } from '../support/contexto';

/** Lunes 12/10/2026 09:00 en Caracas. */
const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');

describe('CitasService — agendamiento y pago retenido', () => {
  it('consulta la disponibilidad sin las franjas ya reservadas', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const antes = await ctx.citas.consultarDisponibilidad(medico.medicoId!, undefined, 1);
    expect(antes).toHaveLength(8);
    await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: 'Control' });
    const despues = await ctx.citas.consultarDisponibilidad(medico.medicoId!, undefined, 1);
    expect(despues).toHaveLength(7);
    expect(despues.some((f) => f.inicio.getTime() === NUEVE_AM.getTime())).toBe(false);
  });

  it('confirma la cita, retiene el pago y notifica al médico', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo', 'MODERADA', 45);
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'VIRTUAL', motivo: 'Cefalea' });
    expect(cita.estado).toBe(EstadoCita.CONFIRMADA);
    expect(cita.monto).toBe(4500);
    expect(cita.politicaAplicada.tipo).toBe('MODERADA');
    const pago = await ctx.pagos.obtenerPorCita(cita.id);
    expect(pago!.estado).toBe(EstadoPago.RETENIDO);
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === medico.id && n.titulo === 'Nueva cita agendada')).toBe(true);
  });

  it('impide la doble reserva de una franja', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const a = await ctx.pacienteTitular('Ana');
    const b = await ctx.pacienteTitular('Beto');
    await ctx.citas.agendar(a.actor, { medicoId: medico.medicoId!, pacienteId: a.perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' });
    await expect(
      ctx.citas.agendar(b.actor, { medicoId: medico.medicoId!, pacienteId: b.perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' }),
    ).rejects.toThrow(ConflictoError);
  });

  it('rechaza horarios fuera de la agenda y perfiles ajenos', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const intruso = await ctx.pacienteTitular('Intruso');
    await expect(
      ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: new Date('2026-10-12T13:10:00.000Z'), modalidad: 'PRESENCIAL', motivo: '' }),
    ).rejects.toThrow(ReglaNegocioError);
    await expect(
      ctx.citas.agendar(intruso.actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' }),
    ).rejects.toThrow(AccesoDenegadoError);
  });

  it('si la pasarela rechaza el pago la cita se cancela y libera la franja', async () => {
    const ctx = crearContexto();
    ctx.pasarela.aprobar = false;
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' });
    expect(cita.estado).toBe(EstadoCita.CANCELADA);
    expect(cita.ocupaFranja).toBe(false);
  });

  it('una cancelación tardía del paciente reembolsa según la política', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo', 'MODERADA', 50);
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' });
    const { reembolso } = await ctx.citas.cancelar(actor, cita.id, 'No llego a tiempo');
    expect(reembolso).toBe(2500);
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.REEMBOLSADO_PARCIAL);
    expect(ctx.pasarela.operaciones).toContain('reembolsar:2500');
  });
});

describe('CitasService — atención, liberación del pago y disputas', () => {
  async function citaAtendida() {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: 'Dolor de cabeza' });
    ctx.reloj.avanzarHoras(1.5);
    await ctx.citas.marcarAtendida(medico, cita.id, { notaClinica: 'Cefalea tensional', diagnosticos: ['Cefalea tensional'] });
    return { ctx, medico, actor, perfil, cita };
  }

  it('registra la consulta y el diagnóstico en el expediente', async () => {
    const { ctx, actor, perfil } = await citaAtendida();
    const linea = await ctx.expediente.obtenerLineaDeTiempo(actor, perfil.id, {});
    expect(linea.items.map((e) => e.tipo).sort()).toEqual([TipoEvento.CONSULTA, TipoEvento.DIAGNOSTICO]);
  });

  it('libera el pago al médico 24 h después', async () => {
    const { ctx, cita } = await citaAtendida();
    expect(await ctx.pagos.liberarPagosVencidos()).toBe(0);
    ctx.reloj.avanzarHoras(24);
    expect(await ctx.pagos.liberarPagosVencidos()).toBe(1);
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.LIBERADO);
  });

  it('un problema reportado retiene el pago hasta la revisión', async () => {
    const { ctx, actor, cita } = await citaAtendida();
    await ctx.citas.reportarProblema(actor, cita.id, 'La consulta duró 5 minutos');
    ctx.reloj.avanzarHoras(48);
    expect(await ctx.pagos.liberarPagosVencidos()).toBe(0);
    const pago = (await ctx.pagos.obtenerPorCita(cita.id))!;
    expect(pago.estado).toBe(EstadoPago.EN_DISPUTA);
    await ctx.pagos.resolverDisputa(pago.id, 'REEMBOLSAR', 'Procede');
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.REEMBOLSADO);
  });

  it('seguimiento: el médico propone, el paciente acepta y se cobra', async () => {
    const { ctx, medico, actor, perfil, cita } = await citaAtendida();
    const proximoLunes = new Date('2026-10-19T13:00:00.000Z');
    const propuesta = await ctx.citas.proponer(medico, { pacienteId: perfil.id, inicio: proximoLunes, modalidad: 'VIRTUAL', citaOrigenId: cita.id });
    expect(propuesta.estado).toBe(EstadoCita.PENDIENTE_ACEPTACION);
    await expect(ctx.citas.aceptarPropuesta(medico, propuesta.id)).rejects.toThrow('otra parte');
    const aceptada = await ctx.citas.aceptarPropuesta(actor, propuesta.id);
    expect(aceptada.estado).toBe(EstadoCita.CONFIRMADA);
    expect((await ctx.pagos.obtenerPorCita(aceptada.id))!.estado).toBe(EstadoPago.RETENIDO);
  });

  it('seguimiento: sin respuesta en 48 h la propuesta se cancela y se notifica a ambos', async () => {
    const { ctx, medico, perfil, cita } = await citaAtendida();
    const propuesta = await ctx.citas.proponer(medico, {
      pacienteId: perfil.id,
      inicio: new Date('2026-10-19T13:30:00.000Z'),
      modalidad: 'PRESENCIAL',
      citaOrigenId: cita.id,
    });
    ctx.notificador.enviadas = [];
    ctx.reloj.avanzarHoras(49);
    expect(await ctx.citas.expirarPropuestas()).toBe(1);
    expect((await ctx.citas.obtenerPorId(propuesta.id)).estado).toBe(EstadoCita.CANCELADA);
    expect(ctx.notificador.enviadas.filter((n) => n.titulo === 'Propuesta vencida')).toHaveLength(2);
  });

  it('el paciente no puede proponer seguimiento sin consulta previa atendida', async () => {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' });
    await expect(
      ctx.citas.proponer(actor, { pacienteId: perfil.id, medicoId: medico.medicoId, inicio: new Date('2026-10-19T13:00:00.000Z'), modalidad: 'VIRTUAL', citaOrigenId: cita.id }),
    ).rejects.toThrow('consulta atendida');
  });
});
