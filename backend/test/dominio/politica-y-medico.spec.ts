import { ReglaNegocioError } from '../../src/shared/domain/errores';
import { EstadoVerificacion } from '../../src/modules/medicos/domain/credencial-profesional';
import { Medico } from '../../src/modules/medicos/domain/medico';
import { PoliticaCancelacion } from '../../src/modules/medicos/domain/politica-cancelacion';

describe('PoliticaCancelacion (HU: configurar mi política de cancelación)', () => {
  it('MODERADA: reembolso total con 24 h o más; 50 % si es más tarde', () => {
    const p = PoliticaCancelacion.desdeTipo('MODERADA');
    expect(p.calcularReembolso(5000, 30)).toBe(5000);
    expect(p.calcularReembolso(5000, 24)).toBe(5000);
    expect(p.calcularReembolso(5000, 5)).toBe(2500);
  });

  it('ESTRICTA: sin reembolso con menos de 48 h', () => {
    const p = PoliticaCancelacion.desdeTipo('ESTRICTA');
    expect(p.calcularReembolso(6500, 47.9)).toBe(0);
    expect(p.calcularReembolso(6500, 48)).toBe(6500);
  });

  it('FLEXIBLE: cancelación gratuita hasta 2 h antes', () => {
    const p = PoliticaCancelacion.desdeTipo('FLEXIBLE');
    expect(p.calcularReembolso(4500, 2)).toBe(4500);
    expect(p.calcularReembolso(4501, 1)).toBe(2250);
    expect(p.descripcion).toContain('2 h');
  });
});

const crearMedico = () =>
  Medico.registrar('u'.repeat(24), { nombres: 'Mateo', apellidos: 'Ruiz', especialidades: ['Medicina General'], tarifaConsulta: 4500 }, new Date());

describe('Medico — verificación profesional (HU: validar título, colegiatura y cédula)', () => {
  it('queda APROBADO solo cuando las tres credenciales están aprobadas', () => {
    const m = crearMedico();
    const ahora = new Date();
    const t = m.registrarCredencial('TITULO', 'UCV-1', 'ref/1', ahora);
    const c = m.registrarCredencial('COLEGIATURA', 'CM-2', 'ref/2', ahora);
    m.aprobarCredencial(t.id, 'admin', ahora);
    m.aprobarCredencial(c.id, 'admin', ahora);
    expect(m.estadoVerificacion).toBe(EstadoVerificacion.PENDIENTE);
    const ced = m.registrarCredencial('CEDULA', 'V-1', 'ref/3', ahora);
    m.aprobarCredencial(ced.id, 'admin', ahora);
    expect(m.estaVerificado()).toBe(true);
  });

  it('un rechazo marca RECHAZADO y exige motivo; recargar vuelve a PENDIENTE', () => {
    const m = crearMedico();
    const t = m.registrarCredencial('TITULO', 'UCV-1', 'ref/1', new Date());
    expect(() => m.rechazarCredencial(t.id, 'admin', '  ', new Date())).toThrow(ReglaNegocioError);
    m.rechazarCredencial(t.id, 'admin', 'Documento ilegible', new Date());
    expect(m.estadoVerificacion).toBe(EstadoVerificacion.RECHAZADO);
    m.registrarCredencial('TITULO', 'UCV-1', 'ref/1b', new Date());
    expect(m.estadoVerificacion).toBe(EstadoVerificacion.PENDIENTE);
    expect(m.credenciales).toHaveLength(1);
  });

  it('no permite revisar dos veces la misma credencial', () => {
    const m = crearMedico();
    const t = m.registrarCredencial('TITULO', 'UCV-1', 'ref/1', new Date());
    m.aprobarCredencial(t.id, 'admin', new Date());
    expect(() => m.aprobarCredencial(t.id, 'admin', new Date())).toThrow('ya fue revisada');
  });
});

describe('Medico — agenda', () => {
  const lunes7amCaracas = new Date('2026-10-12T11:00:00.000Z');

  it('genera franjas en la hora local del médico (UTC-4)', () => {
    const m = crearMedico();
    m.configurarHorario([{ diaSemana: 1, horaInicio: '08:00', horaFin: '12:00', duracionCitaMin: 30 }]);
    const franjas = m.generarFranjas(lunes7amCaracas, 1);
    expect(franjas).toHaveLength(8);
    expect(franjas[0].inicio.toISOString()).toBe('2026-10-12T12:00:00.000Z');
    expect(franjas[7].fin.toISOString()).toBe('2026-10-12T16:00:00.000Z');
  });

  it('no genera franjas para días sin horario ni franjas ya pasadas', () => {
    const m = crearMedico();
    m.configurarHorario([{ diaSemana: 1, horaInicio: '08:00', horaFin: '10:00', duracionCitaMin: 60 }]);
    expect(m.generarFranjas(new Date('2026-10-12T13:30:00.000Z'), 1)).toHaveLength(0);
    expect(m.generarFranjas(new Date('2026-10-17T12:00:00.000Z'), 1)).toHaveLength(0);
  });

  it('valida que una hora pertenezca exactamente a una franja', () => {
    const m = crearMedico();
    m.configurarHorario([{ diaSemana: 1, horaInicio: '08:00', horaFin: '12:00', duracionCitaMin: 30 }]);
    expect(m.franjaQueIniciaEn(new Date('2026-10-12T13:30:00.000Z'))).toBeDefined();
    expect(m.franjaQueIniciaEn(new Date('2026-10-12T13:15:00.000Z'))).toBeUndefined();
  });

  it('rechaza bloques solapados', () => {
    const m = crearMedico();
    expect(() =>
      m.configurarHorario([
        { diaSemana: 2, horaInicio: '08:00', horaFin: '12:00', duracionCitaMin: 30 },
        { diaSemana: 2, horaInicio: '11:00', horaFin: '13:00', duracionCitaMin: 30 },
      ]),
    ).toThrow('solapan');
  });
});
