import { DOSIS_CON_UNIDAD, RecipeDigital } from '../../src/modules/recipes/domain/recipe-digital';

const AHORA = new Date('2026-11-26T12:00:00.000Z');
const datos = (dosis: string) => ({
  citaId: '64b000000000000000000010',
  medicoId: '64b000000000000000000011',
  pacienteId: '64b000000000000000000012',
  items: [{ medicamento: 'Amoxicilina', presentacion: 'Cápsulas 500 mg', dosis, frecuencia: 'cada 8 horas', duracionDias: 7 }],
  validoDias: 30,
});

describe('Récipe con terminología estandarizada', () => {
  it('acepta dosis con unidad del SI, UI o forma farmacéutica', () => {
    for (const d of ['500 mg', '2,5 ml', '10 UI', '1 tableta', '2 cápsulas', '20 gotas', '0.5 g']) {
      expect(DOSIS_CON_UNIDAD.test(d)).toBe(true);
    }
  });

  it('no deja guardar un récipe si la dosis no tiene una unidad válida', () => {
    expect(() => RecipeDigital.borrador(datos('una pastilla'), AHORA)).toThrow(/unidad válida/);
    expect(() => RecipeDigital.borrador(datos('500'), AHORA)).toThrow(/unidad válida/);
    expect(() => RecipeDigital.borrador(datos('500 mg'), AHORA)).not.toThrow();
  });
});
