import { LONGITUD_MAXIMA_MENSAJE, MensajeChat } from '../../src/modules/chat/domain/mensaje-chat';

const AHORA = new Date('2026-11-05T14:00:00.000Z');
const base = { citaId: 'c'.repeat(24), autor: 'PACIENTE' as const, autorUsuarioId: 'u'.repeat(24), destinatarioUsuarioId: 'm'.repeat(24) };

describe('MensajeChat (chat médico-paciente)', () => {
  it('quita los espacios de los extremos y nace sin leer', () => {
    const m = MensajeChat.escribir({ ...base, texto: '  ¿Debo ir en ayunas?  ' }, AHORA);
    expect(m.texto).toBe('¿Debo ir en ayunas?');
    expect(m.leido).toBe(false);
    expect(m.enviadoEn).toEqual(AHORA);
  });

  it('rechaza mensajes vacíos o solo con espacios', () => {
    expect(() => MensajeChat.escribir({ ...base, texto: '' }, AHORA)).toThrow('vacío');
    expect(() => MensajeChat.escribir({ ...base, texto: '   ' }, AHORA)).toThrow('vacío');
  });

  it(`rechaza mensajes de más de ${LONGITUD_MAXIMA_MENSAJE} caracteres`, () => {
    expect(() => MensajeChat.escribir({ ...base, texto: 'a'.repeat(LONGITUD_MAXIMA_MENSAJE + 1) }, AHORA)).toThrow('superar');
    expect(MensajeChat.escribir({ ...base, texto: 'a'.repeat(LONGITUD_MAXIMA_MENSAJE) }, AHORA).texto).toHaveLength(LONGITUD_MAXIMA_MENSAJE);
  });
});
