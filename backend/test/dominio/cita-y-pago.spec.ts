import { ReglaNegocioError } from '../../src/shared/domain/errores';
import { sumarHoras } from '../../src/shared/domain/reloj';
import { Cita, EstadoCita } from '../../src/modules/citas/domain/cita';
import { PoliticaCancelacion } from '../../src/modules/medicos/domain/politica-cancelacion';
import { EstadoPago, Pago } from '../../src/modules/pagos/domain/pago';

const AHORA = new Date('2026-10-12T12:00:00.000Z');

const nuevaCita = (horasHastaInicio: number, politica = PoliticaCancelacion.desdeTipo('MODERADA')) =>
  Cita.agendar(
    {
      pacienteId: 'p'.repeat(24),
      medicoId: 'm'.repeat(24),
      agendadaPorUsuarioId: 'u'.repeat(24),
      inicio: sumarHoras(AHORA, horasHastaInicio),
      fin: sumarHoras(AHORA, horasHastaInicio + 0.5),
      modalidad: 'PRESENCIAL',
      motivo: 'Control',
      monto: 5000,
      moneda: 'USD',
      politica,
    },
    AHORA,
  );

describe('Cita (HU: agendar una consulta con el especialista)', () => {
  it('no se puede agendar en el pasado', () => {
    expect(() => nuevaCita(-1)).toThrow(ReglaNegocioError);
  });

  it('nace pendiente de pago y ocupa la franja', () => {
    const c = nuevaCita(48);
    expect(c.estado).toBe(EstadoCita.PENDIENTE_PAGO);
    expect(c.ocupaFranja).toBe(true);
  });

  it('el paciente recibe reembolso según la política copiada al agendar (D7)', () => {
    const c = nuevaCita(30);
    c.confirmarPago();
    expect(c.cancelar('PACIENTE', 'viaje', AHORA)).toBe(5000);

    const tarde = nuevaCita(5);
    tarde.confirmarPago();
    expect(tarde.cancelar('PACIENTE', 'imprevisto', AHORA)).toBe(2500);
    expect(tarde.estado).toBe(EstadoCita.CANCELADA);
    expect(tarde.ocupaFranja).toBe(false);
  });

  it('si cancela el médico se reembolsa todo', () => {
    const c = nuevaCita(1, PoliticaCancelacion.desdeTipo('ESTRICTA'));
    c.confirmarPago();
    expect(c.cancelar('MEDICO', 'emergencia', AHORA)).toBe(5000);
  });

  it('una cita sin pagar se cancela sin reembolso y no puede cancelarse si ya comenzó', () => {
    expect(nuevaCita(10).cancelar('PACIENTE', 'x', AHORA)).toBe(0);
    const c = nuevaCita(1);
    c.confirmarPago();
    expect(() => c.cancelar('PACIENTE', 'x', sumarHoras(AHORA, 2))).toThrow('ya comenzó');
  });

  it('solo el médico de la cita la marca atendida y no antes de su inicio', () => {
    const c = nuevaCita(3);
    c.confirmarPago();
    expect(() => c.marcarAtendida('m'.repeat(24), AHORA)).toThrow('aún no comienza');
    expect(() => c.marcarAtendida('x'.repeat(24), sumarHoras(AHORA, 3))).toThrow(ReglaNegocioError);
    c.marcarAtendida('m'.repeat(24), sumarHoras(AHORA, 3));
    expect(c.estado).toBe(EstadoCita.ATENDIDA);
  });
});

describe('Cita de seguimiento (HU: ambas partes deben aceptar)', () => {
  const propuesta = () =>
    Cita.proponer(
      {
        pacienteId: 'p'.repeat(24),
        medicoId: 'm'.repeat(24),
        agendadaPorUsuarioId: 'u'.repeat(24),
        inicio: sumarHoras(AHORA, 72),
        fin: sumarHoras(AHORA, 72.5),
        modalidad: 'VIRTUAL',
        motivo: 'Seguimiento',
        monto: 5000,
        moneda: 'USD',
        politica: PoliticaCancelacion.porDefecto(),
        propuestaPor: 'MEDICO',
      },
      AHORA,
    );

  it('queda pendiente de aceptación y solo la otra parte puede aceptarla', () => {
    const c = propuesta();
    expect(c.estado).toBe(EstadoCita.PENDIENTE_ACEPTACION);
    expect(c.parteQueDebeResponder).toBe('PACIENTE');
    expect(() => c.aceptarPropuesta('MEDICO', AHORA)).toThrow('otra parte');
    c.aceptarPropuesta('PACIENTE', sumarHoras(AHORA, 1));
    expect(c.estado).toBe(EstadoCita.PENDIENTE_PAGO);
  });

  it('se cancela si nadie responde en 48 horas', () => {
    const c = propuesta();
    expect(c.expirarPropuesta(sumarHoras(AHORA, 47))).toBe(false);
    expect(c.expirarPropuesta(sumarHoras(AHORA, 48))).toBe(true);
    expect(c.estado).toBe(EstadoCita.CANCELADA);
    expect(c.canceladaPor).toBe('SISTEMA');
  });
});

describe('Pago retenido (HU: el dinero se libera al médico después de la consulta)', () => {
  const pago = (aprobado = true) =>
    Pago.registrar({ citaId: 'c'.repeat(24), pacienteId: 'p'.repeat(24), medicoId: 'm'.repeat(24), monto: 5000, moneda: 'USD' }, { aprobado, referencia: 'R1' }, AHORA);

  it('queda RETENIDO si la pasarela aprueba y FALLIDO si no', () => {
    expect(pago().estado).toBe(EstadoPago.RETENIDO);
    expect(pago(false).estado).toBe(EstadoPago.FALLIDO);
  });

  it('se libera 24 h después de marcar la cita como atendida', () => {
    const p = pago();
    p.programarLiberacion(AHORA);
    expect(p.puedeLiberarse(sumarHoras(AHORA, 23.9))).toBe(false);
    expect(p.puedeLiberarse(sumarHoras(AHORA, 24))).toBe(true);
    p.liberar(sumarHoras(AHORA, 24));
    expect(p.estado).toBe(EstadoPago.LIBERADO);
  });

  it('si el paciente reporta un problema en ese plazo queda retenido hasta revisión', () => {
    const p = pago();
    p.programarLiberacion(AHORA);
    p.abrirDisputa('El médico no se conectó', sumarHoras(AHORA, 2));
    expect(p.estado).toBe(EstadoPago.EN_DISPUTA);
    expect(p.puedeLiberarse(sumarHoras(AHORA, 48))).toBe(false);

    const tarde = pago();
    tarde.programarLiberacion(AHORA);
    expect(() => tarde.abrirDisputa('x', sumarHoras(AHORA, 25))).toThrow('venció');
  });

  it('distingue reembolso total, parcial y nulo', () => {
    const total = pago();
    total.reembolsar(5000, AHORA);
    expect(total.estado).toBe(EstadoPago.REEMBOLSADO);
    const parcial = pago();
    parcial.reembolsar(2500, AHORA);
    expect(parcial.estado).toBe(EstadoPago.REEMBOLSADO_PARCIAL);
    expect(parcial.montoParaMedico).toBe(2500);
    const nulo = pago();
    nulo.reembolsar(0, AHORA);
    expect(nulo.estado).toBe(EstadoPago.LIBERADO);
  });
});
