import { DisputasService } from '../../src/modules/pagos/application/disputas.service';
import { ParticipantesPago, ParticipantesPagoPuerto } from '../../src/modules/pagos/application/participantes-pago';
import { EstadoPago, Pago } from '../../src/modules/pagos/domain/pago';
import { crearContexto } from '../support/contexto';

/** Lunes 12/10/2026 09:00 en Caracas. */
const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');

async function citaEnDisputa() {
  const ctx = crearContexto();
  const medico = await ctx.medicoVerificado('Mateo');
  const { actor, perfil } = await ctx.pacienteTitular();
  const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'VIRTUAL', motivo: 'Control' });
  ctx.reloj.avanzarHoras(1.5);
  await ctx.citas.marcarAtendida(medico, cita.id, { notaClinica: 'Bien' });
  ctx.notificador.enviadas = [];
  await ctx.citas.reportarProblema(actor, cita.id, 'El médico no se conectó');
  class Partes extends ParticipantesPagoPuerto {
    async de(_p: Pago): Promise<ParticipantesPago> {
      return { pacienteNombre: perfil.nombreCompleto, pacienteUsuarioId: actor.id, medicoNombre: 'Dr. Mateo Prueba', medicoUsuarioId: medico.id };
    }
  }
  const disputas = new DisputasService(ctx.pagos, new Partes(), ctx.notificador);
  return { ctx, medico, actor, perfil, cita, disputas };
}

describe('Disputas de pago — avisos al abrir y al resolver', () => {
  it('al reportar un problema se avisa al médico y se confirma al paciente', async () => {
    const { ctx, medico, actor, cita } = await citaEnDisputa();
    const alMedico = ctx.notificador.enviadas.find((n) => n.usuarioId === medico.id);
    const alPaciente = ctx.notificador.enviadas.find((n) => n.usuarioId === actor.id);
    expect(alMedico).toMatchObject({ tipo: 'PAGO', titulo: 'Un paciente reportó un problema', datos: { citaId: cita.id } });
    expect(alMedico!.mensaje).toContain('El médico no se conectó');
    expect(alPaciente).toMatchObject({ tipo: 'PAGO', titulo: 'Recibimos tu reporte' });
  });

  it('lista las disputas abiertas con el paciente y el médico', async () => {
    const { disputas, perfil } = await citaEnDisputa();
    const lista = await disputas.listar();
    expect(lista).toHaveLength(1);
    expect(lista[0].pago.estado).toBe(EstadoPago.EN_DISPUTA);
    expect(lista[0].pago.motivoDisputa).toBe('El médico no se conectó');
    expect(lista[0].partes).toMatchObject({ pacienteNombre: perfil.nombreCompleto, medicoNombre: 'Dr. Mateo Prueba' });
  });

  it('reembolsar devuelve el dinero en la pasarela y avisa a ambos', async () => {
    const { ctx, disputas, medico, actor } = await citaEnDisputa();
    const [d] = await disputas.listar();
    ctx.notificador.enviadas = [];
    const r = await disputas.resolver(d.pago.id, 'REEMBOLSAR', 'No hubo consulta');
    expect(r.pago.estado).toBe(EstadoPago.REEMBOLSADO);
    expect(ctx.pasarela.operaciones).toContain('reembolsar:5000');
    expect(ctx.notificador.enviadas.find((n) => n.usuarioId === actor.id)).toMatchObject({ titulo: 'Reporte resuelto: reembolso aprobado' });
    expect(ctx.notificador.enviadas.find((n) => n.usuarioId === medico.id)?.mensaje).toContain('No hubo consulta');
    expect(await disputas.listar()).toHaveLength(0);
  });

  it('liberar paga al médico y también avisa a ambos', async () => {
    const { ctx, disputas, medico, actor } = await citaEnDisputa();
    const [d] = await disputas.listar();
    ctx.notificador.enviadas = [];
    const r = await disputas.resolver(d.pago.id, 'LIBERAR', '');
    expect(r.pago.estado).toBe(EstadoPago.LIBERADO);
    expect(ctx.pasarela.operaciones).toContain('capturar:5000');
    expect(ctx.notificador.enviadas.map((n) => [n.usuarioId, n.titulo])).toEqual([
      [actor.id, 'Reporte resuelto'],
      [medico.id, 'Pago liberado'],
    ]);
  });

  it('una disputa ya resuelta no se puede resolver de nuevo', async () => {
    const { disputas } = await citaEnDisputa();
    const [d] = await disputas.listar();
    await disputas.resolver(d.pago.id, 'LIBERAR', '');
    await expect(disputas.resolver(d.pago.id, 'REEMBOLSAR', '')).rejects.toThrow();
  });
});
