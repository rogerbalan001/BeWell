import { ClasificadorExamen, SugerenciaClasificacion } from '../../src/modules/examenes/application/clasificador-examen';
import { ExamenesService } from '../../src/modules/examenes/application/examenes.service';
import { ServicioOcr } from '../../src/modules/examenes/application/servicio-ocr';
import { ExamenMedico, ResultadoAnalito, TITULO_SIN_CLASIFICAR } from '../../src/modules/examenes/domain/examen-medico';
import { ExamenRepository, SolicitudExamenRepository } from '../../src/modules/examenes/domain/repositorios';
import { SolicitudExamen } from '../../src/modules/examenes/domain/solicitud-examen';
import { ClasificadorSimuladoAdapter } from '../../src/modules/examenes/infrastructure/clasificador-simulado.adapter';
import { TipoEvento, TODAS_LAS_CATEGORIAS } from '../../src/modules/expediente/domain/categoria-clinica';
import { crearContexto } from '../support/contexto';

class ExamenesMemoria extends ExamenRepository {
  datos = new Map<string, ExamenMedico>();
  async guardar(e: ExamenMedico) {
    this.datos.set(e.id, new ExamenMedico({ ...e }));
  }
  async buscarPorId(id: string) {
    const e = this.datos.get(id);
    return e ? new ExamenMedico({ ...e }) : null;
  }
  async listarPorPaciente(id: string) {
    return [...this.datos.values()].filter((e) => e.pacienteId === id);
  }
}

class SolicitudesMemoria extends SolicitudExamenRepository {
  async guardar(_s: SolicitudExamen) {}
  async buscarPorId() {
    return null;
  }
  async listarPorPaciente() {
    return [];
  }
  async listarPorMedico() {
    return [];
  }
}

class OcrFijo extends ServicioOcr {
  constructor(private readonly analitos: string[]) {
    super();
  }
  async extraer(): Promise<Omit<ResultadoAnalito, 'validadoPorMedico'>[] | null> {
    return this.analitos.length ? this.analitos.map((analito) => ({ analito, valor: '100', confianzaOcr: 0.9 })) : null;
  }
}

class ClasificadorQueFalla extends ClasificadorExamen {
  async clasificar(): Promise<SugerenciaClasificacion | null> {
    throw new Error('Gemini no responde');
  }
}

async function preparar(clasificador: ClasificadorExamen, analitos: string[] = []) {
  const ctx = crearContexto();
  const { actor, perfil } = await ctx.pacienteTitular();
  const repo = new ExamenesMemoria();
  const servicio = new ExamenesService(
    repo,
    new SolicitudesMemoria(),
    new OcrFijo(analitos),
    clasificador,
    ctx.almacenamiento,
    ctx.politica,
    ctx.expediente,
    ctx.citas,
    ctx.perfiles,
    ctx.medicos,
    ctx.notificador,
    ctx.auditoria,
    ctx.reloj,
  );
  const archivo = { contenido: Buffer.from('%PDF'), tipoMime: 'application/pdf', nombreOriginal: 'resultados.pdf' };
  return { ctx, actor, perfil, repo, servicio, archivo };
}

describe('ExamenesService — categoría y tipo sugeridos al subir un examen', () => {
  it('sin título, la app sugiere categoría y tipo y el examen se nombra con el tipo', async () => {
    const { actor, perfil, servicio, archivo } = await preparar(new ClasificadorSimuladoAdapter(), ['Colesterol total', 'Triglicéridos']);
    const examen = await servicio.cargar(actor, { pacienteId: perfil.id }, archivo);
    expect(examen.clasificacion).toMatchObject({ categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', origen: 'IA' });
    expect(examen.titulo).toBe('Perfil lipídico');
    expect(examen.resultados).toHaveLength(2);
  });

  it('si la IA falla, el examen se guarda igual sin clasificar', async () => {
    const { actor, perfil, servicio, archivo, repo } = await preparar(new ClasificadorQueFalla());
    const examen = await servicio.cargar(actor, { pacienteId: perfil.id }, archivo);
    expect(examen.clasificacion).toBeUndefined();
    expect(examen.titulo).toBe(TITULO_SIN_CLASIFICAR);
    expect(await repo.buscarPorId(examen.id)).not.toBeNull();
  });

  it('el paciente elige la categoría y el tipo, y la línea de tiempo toma el nuevo nombre', async () => {
    const { ctx, actor, perfil, servicio, archivo } = await preparar(new ClasificadorQueFalla());
    const examen = await servicio.cargar(actor, { pacienteId: perfil.id }, archivo);
    const corregido = await servicio.corregirClasificacion(actor, examen.id, 'Imagenología', 'Radiografía de tórax');
    expect(corregido.clasificacion).toEqual({ categoria: 'Imagenología', tipo: 'Radiografía de tórax', origen: 'PACIENTE' });
    expect(corregido.titulo).toBe('Radiografía de tórax');
    const { items } = await ctx.repos.eventos.listarPorPaciente(perfil.id, TODAS_LAS_CATEGORIAS, TipoEvento.EXAMEN, { pagina: 1, tamano: 10 });
    const evento = items.find((e) => e.documentoOrigenId === examen.id);
    expect(evento?.titulo).toBe('Radiografía de tórax');
    expect(evento?.detalles).toMatchObject({ categoria: 'Imagenología', tipoExamen: 'Radiografía de tórax' });
  });

  it('otra persona no puede corregir la clasificación', async () => {
    const { ctx, actor, perfil, servicio, archivo } = await preparar(new ClasificadorSimuladoAdapter(), ['TSH']);
    const examen = await servicio.cargar(actor, { pacienteId: perfil.id }, archivo);
    const intruso = await ctx.pacienteTitular('Intruso');
    await expect(servicio.corregirClasificacion(intruso.actor, examen.id, 'Otro', 'Algo')).rejects.toThrow();
  });
});
