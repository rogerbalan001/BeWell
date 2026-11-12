import { AccesoDenegadoError } from '../../src/shared/domain/errores';
import { EstadoCita } from '../../src/modules/citas/domain/cita';
import { EstadoPago } from '../../src/modules/pagos/domain/pago';
import { crearContexto } from '../support/contexto';

/** Lunes 12/10/2026 09:00 en Caracas. */
const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');

async function reservaConPayPal(tarifa = 45) {
  const ctx = crearContexto();
  ctx.pasarela.conAprobacion = true;
  const medico = await ctx.medicoVerificado('Mateo', 'MODERADA', tarifa);
  const { actor, perfil } = await ctx.pacienteTitular();
  const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'VIRTUAL', motivo: 'Control' });
  const pago = (await ctx.pagos.obtenerPorCita(cita.id))!;
  return { ctx, medico, actor, perfil, cita, pago };
}

describe('Pagos con PayPal — la cita espera la aprobación del paciente', () => {
  it('al reservar la cita queda pendiente de pago, con la URL de PayPal y la franja guardada', async () => {
    const { ctx, medico, cita, pago } = await reservaConPayPal();
    expect(cita.estado).toBe(EstadoCita.PENDIENTE_PAGO);
    expect(cita.ocupaFranja).toBe(true);
    expect(pago.estado).toBe(EstadoPago.PENDIENTE_APROBACION);
    expect(pago.proveedor).toBe('PAYPAL');
    expect(pago.urlAprobacion).toContain('paypal.test');
    expect(ctx.pasarela.operaciones).toContain('orden:4500');
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === medico.id && n.titulo === 'Nueva cita agendada')).toBe(false);
  });

  it('al volver de PayPal con el pago aprobado se retiene el monto, se confirma la cita y se avisa', async () => {
    const { ctx, medico, actor, cita, pago } = await reservaConPayPal();
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    const r = await ctx.citas.completarPagoPorOrden(pago.ordenPasarela!);
    expect(r.cita.estado).toBe(EstadoCita.CONFIRMADA);
    expect(r.pago.estado).toBe(EstadoPago.RETENIDO);
    expect(r.pago.referenciaPasarela).toBe(`AUTH-${pago.ordenPasarela}`);
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === medico.id && n.titulo === 'Nueva cita agendada')).toBe(true);
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === actor.id && n.titulo === 'Pago recibido')).toBe(true);
    // Repetir el retorno no vuelve a autorizar ni a notificar.
    const avisos = ctx.notificador.enviadas.length;
    await ctx.citas.completarPagoPorOrden(pago.ordenPasarela!);
    expect(ctx.notificador.enviadas.length).toBe(avisos);
    expect((await ctx.citas.obtenerPorId(cita.id)).estado).toBe(EstadoCita.CONFIRMADA);
  });

  it('"Ya pagué" no confirma mientras el paciente no apruebe, y sí después', async () => {
    const { ctx, actor, cita, pago } = await reservaConPayPal();
    expect((await ctx.citas.verificarPago(actor, cita.id)).estado).toBe(EstadoCita.PENDIENTE_PAGO);
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    expect((await ctx.citas.verificarPago(actor, cita.id)).estado).toBe(EstadoCita.CONFIRMADA);
  });

  it('solo el paciente puede verificar el pago', async () => {
    const { ctx, medico, cita } = await reservaConPayPal();
    const otro = await ctx.pacienteTitular('Otro');
    await expect(ctx.citas.verificarPago(otro.actor, cita.id)).rejects.toThrow(AccesoDenegadoError);
    await expect(ctx.citas.verificarPago(medico, cita.id)).rejects.toThrow(AccesoDenegadoError);
  });

  it('si PayPal rechaza el pago la cita se cancela y la franja se libera', async () => {
    const { ctx, pago } = await reservaConPayPal();
    ctx.pasarela.aprobar = false;
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    const r = await ctx.citas.completarPagoPorOrden(pago.ordenPasarela!);
    expect(r.cita.estado).toBe(EstadoCita.CANCELADA);
    expect(r.cita.ocupaFranja).toBe(false);
    expect(r.pago.estado).toBe(EstadoPago.FALLIDO);
  });

  it('a los 30 minutos sin pagar la reserva se libera y no se cobra nada', async () => {
    const { ctx, actor, cita } = await reservaConPayPal();
    ctx.reloj.avanzarHoras(29 / 60);
    expect(await ctx.citas.expirarPagosPendientes()).toBe(0);
    ctx.reloj.avanzarHoras(1 / 60);
    expect(await ctx.citas.expirarPagosPendientes()).toBe(1);
    expect((await ctx.citas.obtenerPorId(cita.id)).estado).toBe(EstadoCita.CANCELADA);
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.FALLIDO);
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === actor.id && n.titulo === 'Reserva liberada')).toBe(true);
    expect(ctx.pasarela.operaciones.some((o) => o.startsWith('reembolsar') || o.startsWith('capturar'))).toBe(false);
  });

  it('si aprobó pero no volvió a Bewell, la revisión del vencimiento confirma la cita', async () => {
    const { ctx, cita, pago } = await reservaConPayPal();
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    ctx.reloj.avanzarHoras(0.6);
    expect(await ctx.citas.expirarPagosPendientes()).toBe(0);
    expect((await ctx.citas.obtenerPorId(cita.id)).estado).toBe(EstadoCita.CONFIRMADA);
  });

  it('cancelar antes de pagar descarta la orden sin movimientos en PayPal', async () => {
    const { ctx, actor, cita } = await reservaConPayPal();
    const { reembolso } = await ctx.citas.cancelar(actor, cita.id, 'Ya no puedo');
    expect(reembolso).toBe(0);
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.FALLIDO);
    expect(ctx.pasarela.operaciones.some((o) => o.startsWith('reembolsar'))).toBe(false);
  });

  it('cancelar una cita pagada anula la retención en PayPal según la política', async () => {
    const { ctx, actor, cita, pago } = await reservaConPayPal(50);
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    await ctx.citas.completarPagoPorOrden(pago.ordenPasarela!);
    const { reembolso } = await ctx.citas.cancelar(actor, cita.id, 'Viaje');
    expect(reembolso).toBe(2500);
    expect(ctx.pasarela.operaciones).toEqual(expect.arrayContaining(['reembolsar:2500', 'capturar:2500']));
  });

  it('24 h después de la consulta se captura la retención', async () => {
    const { ctx, medico, cita, pago } = await reservaConPayPal();
    ctx.pasarela.aprobadas.add(pago.ordenPasarela!);
    await ctx.citas.completarPagoPorOrden(pago.ordenPasarela!);
    ctx.reloj.avanzarHoras(1.5);
    await ctx.citas.marcarAtendida(medico, cita.id, { notaClinica: 'Bien' });
    ctx.reloj.avanzarHoras(24);
    expect(await ctx.pagos.liberarPagosVencidos()).toBe(1);
    expect(ctx.pasarela.operaciones).toContain('capturar:4500');
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.estado).toBe(EstadoPago.LIBERADO);
  });

  it('los datos de demostración se pagan sin PayPal y nunca le envían operaciones', async () => {
    const ctx = crearContexto();
    ctx.pasarela.conAprobacion = true;
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(
      actor,
      { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'VIRTUAL', motivo: '' },
      { pagoDemo: true },
    );
    expect(cita.estado).toBe(EstadoCita.CONFIRMADA);
    expect((await ctx.pagos.obtenerPorCita(cita.id))!.proveedor).toBe('SIMULADA');
    await ctx.citas.cancelar(actor, cita.id, 'Prueba');
    expect(ctx.pasarela.operaciones).toEqual([]);
  });
});
