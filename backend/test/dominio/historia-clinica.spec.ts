import { ReglaNegocioError } from '../../src/shared/domain/errores';
import { sumarHoras } from '../../src/shared/domain/reloj';
import { AntecedentesClinicos } from '../../src/modules/historia-clinica/domain/antecedentes-clinicos';
import { ConsultaClinica, ContenidoConsulta } from '../../src/modules/historia-clinica/domain/consulta-clinica';

const AHORA = new Date('2026-10-12T12:00:00.000Z');
const PACIENTE = 'p'.repeat(24).replace(/p/g, '1');
const MEDICO = 'm'.repeat(24).replace(/m/g, '2');

const contenido = (cambios: Partial<ContenidoConsulta> = {}): ContenidoConsulta => ({
  motivoConsulta: 'Dolor de cabeza',
  enfermedadActual: 'Cefalea frontal de 3 días de evolución',
  signosVitales: { tensionArterial: '120/80', frecuenciaCardiaca: 72, peso: 70, talla: 175 },
  examenFisico: 'Sin hallazgos patológicos',
  impresionDiagnostica: ['Cefalea tensional'],
  plan: 'Analgésicos y control en 1 semana',
  ...cambios,
});

const registrar = (cambios: Partial<ContenidoConsulta> = {}) =>
  ConsultaClinica.registrar({ ...contenido(cambios), pacienteId: PACIENTE, medicoId: MEDICO, autorUsuarioId: MEDICO, fecha: AHORA }, AHORA);

describe('AntecedentesClinicos (HU: historia clínica — antecedentes)', () => {
  it('limpia espacios, elimina duplicados y vacíos en las listas', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    a.actualizar(
      { alergicos: [' Penicilina ', 'Penicilina', ''], patologicos: ['Asma'], habitos: { tabaco: ' Niega ', alcohol: '  ' }, grupoSanguineo: 'O+' },
      { usuarioId: PACIENTE },
      false,
      AHORA,
    );
    expect(a.datos.alergicos).toEqual(['Penicilina']);
    expect(a.datos.patologicos).toEqual(['Asma']);
    expect(a.datos.habitos).toEqual({ tabaco: 'Niega' });
    expect(a.datos.grupoSanguineo).toBe('O+');
    expect(a.tieneAlergias).toBe(true);
  });

  it('rechaza un grupo sanguíneo inválido', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    expect(() => a.actualizar({ grupoSanguineo: 'Z+' as never }, { usuarioId: PACIENTE }, false, AHORA)).toThrow(ReglaNegocioError);
  });

  it('los gineco-obstétricos solo aplican a pacientes de sexo femenino y deben cuadrar con las gestas', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    expect(() => a.actualizar({ ginecoObstetricos: { gestas: 1 } }, { usuarioId: PACIENTE }, false, AHORA)).toThrow('sexo femenino');
    expect(() => a.actualizar({ ginecoObstetricos: { gestas: 1, partos: 1, cesareas: 1 } }, { usuarioId: PACIENTE }, true, AHORA)).toThrow(
      'gestas',
    );
    a.actualizar({ ginecoObstetricos: { gestas: 2, partos: 1, cesareas: 1, menarquia: '12 años' } }, { usuarioId: PACIENTE }, true, AHORA);
    expect(a.datos.ginecoObstetricos).toEqual({ gestas: 2, partos: 1, cesareas: 1, menarquia: '12 años' });
  });
});

describe('ConsultaClinica (HU: historia clínica — consultas)', () => {
  it('registra la consulta y calcula el IMC', () => {
    const c = registrar();
    expect(c.signosVitales.tensionArterial).toBe('120/80');
    expect(c.imc).toBe(22.9);
  });

  it('exige motivo, enfermedad actual, plan y al menos un diagnóstico', () => {
    expect(() => registrar({ motivoConsulta: ' ' })).toThrow('motivo');
    expect(() => registrar({ enfermedadActual: '' })).toThrow('enfermedad actual');
    expect(() => registrar({ plan: '' })).toThrow('plan');
    expect(() => registrar({ impresionDiagnostica: [' '] })).toThrow('impresión diagnóstica');
  });

  it('valida el formato de la tensión arterial y los rangos de los signos vitales', () => {
    expect(() => registrar({ signosVitales: { tensionArterial: '120-80' } })).toThrow('sistólica/diastólica');
    expect(() => registrar({ signosVitales: { tensionArterial: '80/120' } })).toThrow('fuera de rango');
    expect(() => registrar({ signosVitales: { temperatura: 50 } })).toThrow('temperatura');
    expect(() => registrar({ signosVitales: { saturacionOxigeno: 120 } })).toThrow('saturación');
  });

  it('no acepta una fecha futura', () => {
    expect(() =>
      ConsultaClinica.registrar(
        { ...contenido(), pacienteId: PACIENTE, medicoId: MEDICO, autorUsuarioId: MEDICO, fecha: sumarHoras(AHORA, 5) },
        AHORA,
      ),
    ).toThrow('futura');
  });

  it('solo el médico autor la corrige y únicamente durante 24 horas', () => {
    const c = registrar();
    expect(() => c.corregir('3'.repeat(24), contenido({ plan: 'Otro' }), AHORA)).toThrow('médico que registró');
    c.corregir(MEDICO, contenido({ plan: 'Control en 3 días' }), sumarHoras(AHORA, 2));
    expect(c.plan).toBe('Control en 3 días');
    expect(c.puedeEditar(MEDICO, sumarHoras(AHORA, 25))).toBe(false);
    expect(() => c.corregir(MEDICO, contenido(), sumarHoras(AHORA, 25))).toThrow('24 horas');
  });
});
