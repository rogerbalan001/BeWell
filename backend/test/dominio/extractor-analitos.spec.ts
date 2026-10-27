import { extraerAnalitos, normalizarNumero } from '../../src/modules/examenes/domain/extractor-analitos';
import { EstadoExtraccion, ExamenMedico } from '../../src/modules/examenes/domain/examen-medico';

const PERFIL_LIPIDICO = `
LABORATORIO CLÍNICO SAN JOSÉ
Paciente: Sofía Morales            Fecha: 30/09/2026
PERFIL LIPÍDICO
Colesterol Total ........ 182 mg/dL      Deseable < 200
Colesterol HDL            58 mg/dl       40 - 60
Colesterol LDL            104 mg/dL      < 130
Triglicéridos             98 mg/dL       hasta 150
`;

const HEMATOLOGIA = `
HEMATOLOGÍA COMPLETA
Hemoglobina   14,2  g/dL   13,5 - 17,5
Hematocrito   42 %          41 - 53
Leucocitos    6.800 /mm3    4.500 - 11.000
Plaquetas     250.000 /mm³  150.000 - 450.000
`;

describe('extraerAnalitos (HU: subir fotos o PDF y que la app extraiga los valores)', () => {
  it('reconoce los valores, la unidad y el rango de un perfil lipídico', () => {
    const r = extraerAnalitos(PERFIL_LIPIDICO);
    const por = new Map(r.map((x) => [x.analito, x]));
    expect(por.get('Colesterol total')).toMatchObject({ valor: '182', unidad: 'mg/dL', rangoReferencia: '< 200' });
    expect(por.get('Colesterol HDL')).toMatchObject({ valor: '58', unidad: 'mg/dL', rangoReferencia: '40 – 60' });
    expect(por.get('Colesterol LDL')).toMatchObject({ valor: '104', rangoReferencia: '< 130' });
    expect(por.get('Triglicéridos')).toMatchObject({ valor: '98', rangoReferencia: '< 150' });
    expect(r).toHaveLength(4);
  });

  it('no confunde el colesterol HDL/LDL con el colesterol total', () => {
    const r = extraerAnalitos('Colesterol HDL 58 mg/dL');
    expect(r.map((x) => x.analito)).toEqual(['Colesterol HDL']);
  });

  it('entiende la coma decimal y el punto de miles de los conteos', () => {
    const por = new Map(extraerAnalitos(HEMATOLOGIA).map((x) => [x.analito, x]));
    expect(por.get('Hemoglobina')).toMatchObject({ valor: '14.2', unidad: 'g/dL', rangoReferencia: '13.5 – 17.5' });
    expect(por.get('Leucocitos')?.valor).toBe('6800');
    expect(por.get('Plaquetas')).toMatchObject({ valor: '250000', unidad: '/mm³' });
  });

  it('distingue la HbA1c de la hemoglobina', () => {
    const r = extraerAnalitos('Hemoglobina glicosilada (HbA1c)  5,4 %   < 5,7');
    expect(r).toEqual([expect.objectContaining({ analito: 'Hemoglobina glicosilada (HbA1c)', valor: '5.4', unidad: '%', rangoReferencia: '< 5.7' })]);
  });

  it('usa la unidad habitual cuando el documento no la trae y baja la confianza', () => {
    const [completo] = extraerAnalitos('Glucosa 88 mg/dL 70 - 100');
    const [incompleto] = extraerAnalitos('Glucosa 88');
    expect(incompleto.unidad).toBe('mg/dL');
    expect(incompleto.confianzaOcr!).toBeLessThan(completo.confianzaOcr!);
  });

  it('la confianza del motor de OCR reduce la confianza del valor', () => {
    const [nitido] = extraerAnalitos('Creatinina 0,9 mg/dL 0,6 - 1,3', 1);
    const [borroso] = extraerAnalitos('Creatinina 0,9 mg/dL 0,6 - 1,3', 0.5);
    expect(borroso.confianzaOcr!).toBeLessThan(nitido.confianzaOcr!);
    expect(borroso.valor).toBe('0.9');
  });

  it('no devuelve nada si el texto no tiene analitos conocidos (el examen queda como adjunto)', () => {
    const r = extraerAnalitos('Informe de radiología de tórax. Sin hallazgos patológicos.');
    expect(r).toEqual([]);
    const examen = ExamenMedico.cargar(
      {
        pacienteId: 'p'.repeat(24),
        titulo: 'Rx de tórax',
        archivoRef: 'examenes/x.pdf',
        tipoMime: 'application/pdf',
        nombreArchivo: 'rx.pdf',
        tamanoBytes: 1000,
        cargadoPorUsuarioId: 'u'.repeat(24),
      },
      new Date('2026-10-12T12:00:00.000Z'),
    );
    examen.registrarExtraccion(r.length ? r.map((x) => ({ ...x, validadoPorMedico: false })) : null);
    expect(examen.estadoExtraccion).toBe(EstadoExtraccion.NO_RECONOCIDO);
  });
});

describe('normalizarNumero', () => {
  it('convierte los formatos latinos a punto decimal', () => {
    expect(normalizarNumero('14,2')).toBe('14.2');
    expect(normalizarNumero('1.234,5')).toBe('1234.5');
    expect(normalizarNumero('1.5')).toBe('1.5');
    expect(normalizarNumero('250.000', true)).toBe('250000');
  });
});
