import {
  CitaParaRecordar,
  FuentesRecordatorio,
  OrdenParaRecordar,
  RecipeParaRecordar,
} from '../../src/modules/recordatorios/application/fuentes-recordatorio';
import { RecordatoriosService } from '../../src/modules/recordatorios/application/recordatorios.service';
import { PreferenciasRecordatorio } from '../../src/modules/recordatorios/domain/preferencias-recordatorio';
import { PreferenciasRecordatorioRepository, RegistroEnviosRepository } from '../../src/modules/recordatorios/domain/repositorios';
import { crearContexto } from '../support/contexto';

class FuentesMemoria extends FuentesRecordatorio {
  citas: CitaParaRecordar[] = [];
  recipes: RecipeParaRecordar[] = [];
  ordenes: OrdenParaRecordar[] = [];
  private filtrar = <T extends { pacienteId: string }>(xs: T[], ids?: string[]) => (ids ? xs.filter((x) => ids.includes(x.pacienteId)) : xs);
  async citasConfirmadasEntre(desde: Date, hasta: Date, ids?: string[]) {
    return this.filtrar(this.citas, ids).filter((c) => c.inicio > desde && c.inicio <= hasta);
  }
  async recipesVigentes(desde: Date, ids?: string[]) {
    return this.filtrar(this.recipes, ids).filter((r) => r.emitidoEn >= desde);
  }
  async ordenesPendientes(desde: Date, ids?: string[]) {
    return this.filtrar(this.ordenes, ids).filter((o) => o.creadaEn >= desde);
  }
}

class PreferenciasMemoria extends PreferenciasRecordatorioRepository {
  datos = new Map<string, PreferenciasRecordatorio>();
  async buscar(id: string) {
    return this.datos.get(id) ?? null;
  }
  async guardar(p: PreferenciasRecordatorio) {
    this.datos.set(p.usuarioId, p);
  }
}

class EnviosMemoria extends RegistroEnviosRepository {
  claves = new Set<string>();
  async registrarSiNuevo(clave: string) {
    if (this.claves.has(clave)) return false;
    this.claves.add(clave);
    return true;
  }
}

async function preparar() {
  const ctx = crearContexto();
  const fuentes = new FuentesMemoria();
  const servicio = new RecordatoriosService(fuentes, new PreferenciasMemoria(), new EnviosMemoria(), ctx.perfiles, ctx.medicos, ctx.notificador, ctx.reloj);
  const medico = await ctx.medicoVerificado('Mateo');
  const { actor, perfil } = await ctx.pacienteTitular();
  return { ctx, fuentes, servicio, medico, actor, perfil };
}

describe('RecordatoriosService (HU-5)', () => {
  it('avisa 24 horas y 1 hora antes de una cita confirmada, una sola vez cada uno', async () => {
    const { ctx, fuentes, servicio, medico, perfil } = await preparar();
    const inicio = new Date(ctx.reloj.ahora().getTime() + 24 * 3_600_000);
    fuentes.citas.push({ id: 'c'.repeat(24), pacienteId: perfil.id, medicoId: medico.medicoId!, inicio, modalidad: 'PRESENCIAL' });

    expect(await servicio.enviarPendientes()).toBe(1);
    expect(await servicio.enviarPendientes()).toBe(0); // idempotente
    expect(ctx.notificador.enviadas.at(-1)).toMatchObject({ tipo: 'RECORDATORIO', titulo: 'Tu cita es mañana' });

    ctx.reloj.avanzarHoras(23);
    expect(await servicio.enviarPendientes()).toBe(1);
    expect(ctx.notificador.enviadas.at(-1)?.titulo).toBe('Tu cita es en 1 hora');
  });

  it('recuerda cada toma del récipe en su hora', async () => {
    const { ctx, fuentes, servicio, perfil } = await preparar();
    // Emitido a las 11:30; la primera toma (12:00) coincide con la hora actual del reloj de prueba.
    const emitido = new Date(ctx.reloj.ahora().getTime() - 30 * 60_000);
    fuentes.recipes.push({
      id: 'r'.repeat(24),
      pacienteId: perfil.id,
      emitidoEn: emitido,
      items: [{ medicamento: 'Loratadina', presentacion: 'Tabletas 10 mg', dosis: '1 tableta', frecuencia: 'cada 24 h', duracionDias: 3 }],
    });
    expect(await servicio.enviarPendientes()).toBe(1);
    expect(ctx.notificador.enviadas.at(-1)?.mensaje).toContain('Toma 1 de 3');
  });

  it('no envía los tipos que el paciente desactivó', async () => {
    const { ctx, fuentes, servicio, medico, actor, perfil } = await preparar();
    await servicio.actualizarPreferencias(actor, { citas: false });
    fuentes.citas.push({
      id: 'c'.repeat(24),
      pacienteId: perfil.id,
      medicoId: medico.medicoId!,
      inicio: new Date(ctx.reloj.ahora().getTime() + 24 * 3_600_000),
      modalidad: 'VIRTUAL',
    });
    expect(await servicio.enviarPendientes()).toBe(0);
  });

  it('recuerda una orden de exámenes pendiente al día siguiente y nombra al dependiente', async () => {
    const { ctx, fuentes, servicio, actor } = await preparar();
    const lucas = await ctx.perfiles.crearPerfilFamiliar(actor.id, 'HIJO', {
      nombres: 'Lucas',
      apellidos: 'Morales',
      fechaNacimiento: new Date('2019-03-02'),
      sexo: 'M',
    });
    fuentes.ordenes.push({ id: 'o'.repeat(24), pacienteId: lucas.id, examenes: ['Hematología completa'], creadaEn: new Date(ctx.reloj.ahora().getTime() - 24 * 3_600_000) });
    expect(await servicio.enviarPendientes()).toBe(1);
    expect(ctx.notificador.enviadas.at(-1)).toMatchObject({ usuarioId: actor.id, titulo: 'Lucas tiene exámenes pendientes' });
  });

  it('lista los próximos recordatorios del usuario ordenados por hora', async () => {
    const { ctx, fuentes, servicio, medico, actor, perfil } = await preparar();
    fuentes.citas.push({
      id: 'c'.repeat(24),
      pacienteId: perfil.id,
      medicoId: medico.medicoId!,
      inicio: new Date(ctx.reloj.ahora().getTime() + 48 * 3_600_000),
      modalidad: 'PRESENCIAL',
    });
    const proximos = await servicio.proximos(actor);
    expect(proximos.map((r) => r.titulo)).toEqual(['Tu cita es mañana', 'Tu cita es en 1 hora']);
    expect(proximos[0].programadoPara.getTime()).toBeLessThan(proximos[1].programadoPara.getTime());
  });
});
