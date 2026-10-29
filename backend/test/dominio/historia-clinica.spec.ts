import { ReglaNegocioError } from '../../src/shared/domain/errores';
import { sumarHoras } from '../../src/shared/domain/reloj';
import { AntecedentesClinicos } from '../../src/modules/historia-clinica/domain/antecedentes-clinicos';
import { ConsultaClinica, ContenidoConsulta } from '../../src/modules/historia-clinica/domain/consulta-clinica';
import { antecedentesLucas, antecedentesSofia, consultaCefalea, consultaChequeo } from '../../src/seed/historia-demo';

const AHORA = new Date('2026-10-12T12:00:00.000Z');
const PACIENTE = 'p'.repeat(24).replace(/p/g, '1');
const MEDICO = 'm'.repeat(24).replace(/m/g, '2');

const contenido = (cambios: Partial<ContenidoConsulta> = {}): ContenidoConsulta => ({
  motivoConsulta: 'Dolor de cabeza',
  enfermedadActual: 'Cefalea frontal de 3 días de evolución',
  signosVitales: { tensionArterial: '120/80', frecuenciaCardiaca: 72, peso: 70, talla: 175 },
  revisionSistemas: {},
  examenRegiones: {},
  examenes: {},
  examenFisico: 'Sin hallazgos patológicos',
  listaProblemas: ['Cefalea'],
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
    expect(a.datos.infancia).toEqual([]);
    expect(a.datos.grupoSanguineo).toBe('O+');
    expect(a.tieneAlergias).toBe(true);
  });

  it('guarda los datos sociales y los antecedentes traumatológicos, transfusionales y epidemiológicos', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    a.actualizar(
      {
        datosSociales: { estadoCivil: 'Casada', ocupacion: ' Docente ', procedencia: '' },
        traumatologicos: ['Fractura de radio (2010)'],
        transfusionales: ['Niega'],
        epidemiologicos: ['Viaje a zona endémica de dengue'],
        infancia: ['Varicela'],
      },
      { usuarioId: PACIENTE },
      false,
      AHORA,
    );
    expect(a.datos.datosSociales).toEqual({ estadoCivil: 'Casada', ocupacion: 'Docente' });
    expect(a.datos.traumatologicos).toEqual(['Fractura de radio (2010)']);
    expect(a.datos.epidemiologicos).toHaveLength(1);
    expect(a.datos.infancia).toEqual(['Varicela']);
  });

  it('agrupa los antecedentes familiares por tipo y convierte la lista antigua en "otros"', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    a.actualizar({ familiares: { metabolicos: [' Padre: diabetes '], neoplasias: [] } }, { usuarioId: PACIENTE }, false, AHORA);
    expect(a.datos.familiares).toEqual({ metabolicos: ['Padre: diabetes'] });
    a.actualizar({ familiares: ['Madre: HTA'] as never }, { usuarioId: PACIENTE }, false, AHORA);
    expect(a.datos.familiares).toEqual({ otros: ['Madre: HTA'] });
  });

  it('guarda la identificación completa y los antecedentes de parasitosis, infecciones, laborales e intoxicaciones', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    a.actualizar(
      {
        datosSociales: { nacionalidad: 'Venezolana', religion: 'Católica', contactoEmergencia: 'Carlos', inventado: 'x' } as never,
        parasitosis: ['Amibiasis'],
        infecciones: ['Hepatitis A'],
        laborales: ['Exposición a polvo'],
        intoxicaciones: ['Monóxido de carbono (2015)'],
      },
      { usuarioId: PACIENTE },
      false,
      AHORA,
    );
    expect(a.datos.datosSociales).toEqual({ nacionalidad: 'Venezolana', religion: 'Católica', contactoEmergencia: 'Carlos' });
    expect(a.datos.parasitosis).toEqual(['Amibiasis']);
    expect(a.datos.intoxicaciones).toHaveLength(1);
    expect(a.datos.radiaciones).toEqual([]);
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
    expect(registrar({ plan: '', planDiagnostico: 'Laboratorio' }).planDiagnostico).toBe('Laboratorio');
    expect(() => registrar({ impresionDiagnostica: [' '] })).toThrow('impresión diagnóstica');
  });

  it('valida el formato de la tensión arterial y los rangos de los signos vitales', () => {
    expect(() => registrar({ signosVitales: { tensionArterial: '120-80' } })).toThrow('sistólica/diastólica');
    expect(() => registrar({ signosVitales: { tensionArterial: '80/120' } })).toThrow('fuera de rango');
    expect(() => registrar({ signosVitales: { temperatura: 50 } })).toThrow('temperatura');
    expect(() => registrar({ signosVitales: { saturacionOxigeno: 120 } })).toThrow('saturación');
    expect(() => registrar({ signosVitales: { circunferenciaAbdominal: 400 } })).toThrow('circunferencia');
  });

  it('guarda las secciones del modelo integral: estímulo iatrotrópico, problemas y exámenes', () => {
    const c = registrar({ estimuloIatrotropico: ' Ya no puede trabajar ', listaProblemas: ['Cefalea', 'Cefalea', ' '], examenes: { laboratorio: 'Hematología', otros: ' ' } });
    expect(c.estimuloIatrotropico).toBe('Ya no puede trabajar');
    expect(c.listaProblemas).toEqual(['Cefalea']);
    expect(c.examenes).toEqual({ laboratorio: 'Hematología' });
  });

  it('guarda la revisión por sistemas y el examen físico por región, sin claves ajenas al modelo', () => {
    const c = registrar({
      revisionSistemas: { cabeza: ' Cefalea frontal ', piel: '', inventado: 'x' } as never,
      examenRegiones: { neurologico: 'Sin déficit focal', ganglios: 'No palpables' },
      resumenDatosPositivos: 'Cefalea frontal',
      consentimientoInformado: true,
      signosVitales: { tensionArterialAcostado: '118/76', tensionArterialDePie: '115 / 75' },
    });
    expect(c.revisionSistemas).toEqual({ cabeza: 'Cefalea frontal' });
    expect(c.examenRegiones).toEqual({ neurologico: 'Sin déficit focal', ganglios: 'No palpables' });
    expect(c.consentimientoInformado).toBe(true);
    expect(c.signosVitales).toEqual({ tensionArterialAcostado: '118/76', tensionArterialDePie: '115/75' });
    expect(() => registrar({ signosVitales: { tensionArterialDePie: '80/120' } })).toThrow('fuera de rango');
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

describe('Historia clínica de demostración (seed)', () => {
  it('cumple las reglas del dominio', () => {
    const a = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    a.actualizar(antecedentesSofia('2026-10-01'), { usuarioId: PACIENTE }, true, AHORA);
    expect(a.datos.familiares.metabolicos).toHaveLength(2);
    expect(a.datos.datosSociales.religion).toBe('Católica');
    const lucas = AntecedentesClinicos.abrir(PACIENTE, AHORA);
    lucas.actualizar(antecedentesLucas, { usuarioId: PACIENTE }, false, AHORA);
    for (const c of [consultaChequeo, consultaCefalea]) {
      const r = ConsultaClinica.registrar({ ...c, pacienteId: PACIENTE, medicoId: MEDICO, autorUsuarioId: MEDICO, fecha: AHORA }, AHORA);
      expect(Object.keys(r.examenRegiones).length).toBeGreaterThan(4);
    }
  });
});
