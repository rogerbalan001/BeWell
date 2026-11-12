import { sumarHoras } from '../../src/shared/domain/reloj';
import { EstadoPago, MINUTOS_PARA_APROBAR_PAGO, Pago } from '../../src/modules/pagos/domain/pago';

const AHORA = new Date('2026-10-12T12:00:00.000Z');
const datos = { citaId: 'c'.repeat(24), pacienteId: 'p'.repeat(24), medicoId: 'm'.repeat(24), monto: 5000, moneda: 'USD' };
const orden = { proveedor: 'PAYPAL', orden: 'ORD-1', urlAprobacion: 'https://www.sandbox.paypal.com/checkoutnow?token=ORD-1' };
const minutos = (m: number) => sumarHoras(AHORA, m / 60);

describe('Pago con PayPal (el paciente aprueba el pago antes de confirmar la cita)', () => {
  it('empieza pendiente de aprobación con la URL de PayPal', () => {
    const p = Pago.iniciar(datos, orden, AHORA);
    expect(p.estado).toBe(EstadoPago.PENDIENTE_APROBACION);
    expect(p.pendienteDeAprobacion).toBe(true);
    expect(p.proveedor).toBe('PAYPAL');
    expect(p.urlAprobacion).toContain('token=ORD-1');
    expect(p.referenciaPasarela).toBeUndefined();
  });

  it('queda RETENIDO con la autorización cuando el paciente aprueba', () => {
    const p = Pago.iniciar(datos, orden, AHORA);
    p.aplicarAutorizacion({ aprobado: true, referencia: 'AUTH-9' }, minutos(5));
    expect(p.estado).toBe(EstadoPago.RETENIDO);
    expect(p.referenciaPasarela).toBe('AUTH-9');
    expect(p.urlAprobacion).toBeUndefined();
  });

  it('no cambia si el paciente aún no aprueba y queda FALLIDO si PayPal rechaza', () => {
    const p = Pago.iniciar(datos, orden, AHORA);
    p.aplicarAutorizacion({ aprobado: false, pendiente: true }, minutos(1));
    expect(p.estado).toBe(EstadoPago.PENDIENTE_APROBACION);
    p.aplicarAutorizacion({ aprobado: false, mensaje: 'Tarjeta rechazada' }, minutos(2));
    expect(p.estado).toBe(EstadoPago.FALLIDO);
    expect(() => p.aplicarAutorizacion({ aprobado: true, referencia: 'X' }, minutos(3))).toThrow('PENDIENTE_APROBACION');
  });

  it(`vence a los ${MINUTOS_PARA_APROBAR_PAGO} minutos y se descarta sin cobrar`, () => {
    const p = Pago.iniciar(datos, orden, AHORA);
    expect(p.aprobacionVencida(minutos(MINUTOS_PARA_APROBAR_PAGO - 1))).toBe(false);
    expect(p.aprobacionVencida(minutos(MINUTOS_PARA_APROBAR_PAGO))).toBe(true);
    p.descartar('No aprobó a tiempo', minutos(MINUTOS_PARA_APROBAR_PAGO));
    expect(p.estado).toBe(EstadoPago.FALLIDO);
    expect(p.montoReembolsado).toBe(0);
  });

  it('exige la orden y su URL', () => {
    expect(() => Pago.iniciar(datos, { ...orden, urlAprobacion: '' }, AHORA)).toThrow('orden de pago');
  });
});
