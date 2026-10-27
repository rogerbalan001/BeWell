import { horasEntreTomas, tomasDelTratamiento, primeraToma, enVentana } from '../../src/modules/recordatorios/domain/planificacion';
import { PreferenciasRecordatorio, TipoRecordatorio } from '../../src/modules/recordatorios/domain/preferencias-recordatorio';

const EMITIDO = new Date('2026-10-12T14:20:00.000Z');

describe('Planificación de recordatorios de medicamentos (HU-5)', () => {
  it('entiende las frecuencias que escriben los médicos', () => {
    expect(horasEntreTomas('cada 8 h')).toBe(8);
    expect(horasEntreTomas('Cada 12 horas')).toBe(12);
    expect(horasEntreTomas('c/6h')).toBe(6);
    expect(horasEntreTomas('cada 24 h')).toBe(24);
    expect(horasEntreTomas('una vez al día')).toBe(24);
    expect(horasEntreTomas('dos veces al día')).toBe(12);
    expect(horasEntreTomas('3 veces al dia')).toBe(8);
    expect(horasEntreTomas('diario')).toBe(24);
    expect(horasEntreTomas('cada 2 días')).toBe(48);
  });

  it('no programa tomas cuando el medicamento es "si hay dolor" o la frecuencia no se entiende', () => {
    expect(horasEntreTomas('si hay dolor')).toBeNull();
    expect(horasEntreTomas('SOS')).toBeNull();
    expect(horasEntreTomas('según indicación')).toBeNull();
    expect(tomasDelTratamiento(EMITIDO, { frecuencia: 'si hay fiebre', duracionDias: 5 })).toEqual([]);
  });

  it('la primera toma es la siguiente hora en punto y las demás siguen la frecuencia hasta terminar el tratamiento', () => {
    expect(primeraToma(EMITIDO)).toEqual(new Date('2026-10-12T15:00:00.000Z'));
    const tomas = tomasDelTratamiento(EMITIDO, { frecuencia: 'cada 8 h', duracionDias: 2 });
    expect(tomas).toHaveLength(6);
    expect(tomas[1]).toEqual(new Date('2026-10-12T23:00:00.000Z'));
    expect(tomas[tomas.length - 1].getTime()).toBeLessThan(EMITIDO.getTime() + 2 * 24 * 3_600_000);
  });

  it('la ventana excluye el inicio e incluye el final', () => {
    const t = new Date('2026-10-12T15:00:00.000Z');
    expect(enVentana(t, new Date('2026-10-12T14:45:00.000Z'), t)).toBe(true);
    expect(enVentana(t, t, new Date('2026-10-12T15:15:00.000Z'))).toBe(false);
  });
});

describe('PreferenciasRecordatorio (criterio 3: activar o desactivar cada tipo)', () => {
  it('todo viene activado y se puede apagar por tipo', () => {
    const p = PreferenciasRecordatorio.porDefecto('u'.repeat(24), EMITIDO);
    expect(p.permite(TipoRecordatorio.CITAS)).toBe(true);
    p.actualizar({ medicamentos: false }, EMITIDO);
    expect(p.permite(TipoRecordatorio.MEDICAMENTOS)).toBe(false);
    expect(p.permite(TipoRecordatorio.EXAMENES)).toBe(true);
  });
});
