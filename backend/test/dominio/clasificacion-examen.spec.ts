import { categoriaValida, CATEGORIA_OTRO, tipoNormalizado } from '../../src/modules/examenes/domain/clasificacion-examen';
import { ExamenMedico, TITULO_SIN_CLASIFICAR } from '../../src/modules/examenes/domain/examen-medico';

const AHORA = new Date('2026-11-05T14:00:00.000Z');
const datos = {
  pacienteId: 'p'.repeat(24),
  archivoRef: 'examenes/a.pdf',
  tipoMime: 'application/pdf',
  nombreArchivo: 'a.pdf',
  tamanoBytes: 1000,
  cargadoPorUsuarioId: 'u'.repeat(24),
};

describe('Clasificación de exámenes (IA)', () => {
  it('sin título, el examen toma el tipo que sugiere la IA', () => {
    const e = ExamenMedico.cargar(datos, AHORA);
    expect(e.titulo).toBe(TITULO_SIN_CLASIFICAR);
    expect(e.tituloAutomatico).toBe(true);
    e.registrarSugerencia({ categoria: 'laboratorio clinico', tipo: 'perfil lipidico', confianza: 0.92 });
    expect(e.clasificacion).toEqual({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', confianza: 0.92, origen: 'IA' });
    expect(e.titulo).toBe('Perfil lipídico');
  });

  it('si el paciente escribió un título, la sugerencia no lo cambia', () => {
    const e = ExamenMedico.cargar({ ...datos, titulo: '  Control de marzo ' }, AHORA);
    e.registrarSugerencia({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', confianza: 0.9 });
    expect(e.titulo).toBe('Control de marzo');
    expect(e.clasificacion?.tipo).toBe('Perfil lipídico');
  });

  it('sin sugerencia queda sin clasificar', () => {
    const e = ExamenMedico.cargar(datos, AHORA);
    e.registrarSugerencia(null);
    expect(e.clasificacion).toBeUndefined();
    expect(e.titulo).toBe(TITULO_SIN_CLASIFICAR);
  });

  it('el paciente corrige la sugerencia: queda con origen PACIENTE y sin confianza', () => {
    const e = ExamenMedico.cargar(datos, AHORA);
    e.registrarSugerencia({ categoria: 'Laboratorio clínico', tipo: 'Glicemia en ayunas', confianza: 0.6 });
    e.corregirClasificacion('Laboratorio clínico', 'Hemoglobina glicosilada (HbA1c)');
    expect(e.clasificacion).toEqual({ categoria: 'Laboratorio clínico', tipo: 'Hemoglobina glicosilada (HbA1c)', origen: 'PACIENTE' });
    expect(e.titulo).toBe('Hemoglobina glicosilada (HbA1c)');
    expect(() => e.corregirClasificacion('Imagenología', '  ')).toThrow('tipo');
  });

  it('una categoría desconocida pasa a "Otro" y los tipos fuera del catálogo se conservan', () => {
    expect(categoriaValida('IMAGENOLOGÍA')).toBe('Imagenología');
    expect(categoriaValida('Odontología')).toBe(CATEGORIA_OTRO);
    expect(tipoNormalizado('radiografía de TÓRAX')).toBe('Radiografía de tórax');
    expect(tipoNormalizado(' Prueba de embarazo ')).toBe('Prueba de embarazo');
  });

  it('la confianza se limita entre 0 y 1', () => {
    const e = ExamenMedico.cargar(datos, AHORA);
    e.registrarSugerencia({ categoria: 'Cardiología', tipo: 'Electrocardiograma', confianza: 7 });
    expect(e.clasificacion?.confianza).toBe(1);
  });
});
