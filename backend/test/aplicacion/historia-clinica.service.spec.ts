import { AccesoDenegadoError, ConflictoError } from '../../src/shared/domain/errores';
import { sumarDias } from '../../src/shared/domain/reloj';
import { CategoriaClinica, TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { HistoriaClinicaService } from '../../src/modules/historia-clinica/application/historia-clinica.service';
import { AntecedentesClinicos } from '../../src/modules/historia-clinica/domain/antecedentes-clinicos';
import { ConsultaClinica, ContenidoConsulta } from '../../src/modules/historia-clinica/domain/consulta-clinica';
import { AntecedentesClinicosRepository, ConsultaClinicaRepository } from '../../src/modules/historia-clinica/domain/repositorios';
import { GeneradorPdfTexto } from '../../src/shared/infrastructure/pdf/generador-pdf-texto';
import { crearContexto } from '../support/contexto';

class AntecedentesMemoria extends AntecedentesClinicosRepository {
  datos = new Map<string, AntecedentesClinicos>();
  async guardar(a: AntecedentesClinicos) {
    this.datos.set(a.pacienteId, new AntecedentesClinicos(a.id, a.pacienteId, structuredClone(a.datos), a.actualizadoEn, a.actualizadoPorUsuarioId, a.actualizadoPorMedicoId));
  }
  async buscarPorPaciente(pacienteId: string) {
    const a = this.datos.get(pacienteId);
    return a ? new AntecedentesClinicos(a.id, a.pacienteId, structuredClone(a.datos), a.actualizadoEn, a.actualizadoPorUsuarioId, a.actualizadoPorMedicoId) : null;
  }
}

class ConsultasMemoria extends ConsultaClinicaRepository {
  datos = new Map<string, ConsultaClinica>();
  private copia = (c: ConsultaClinica) => new ConsultaClinica(structuredClone({ ...c }));
  async guardar(c: ConsultaClinica) {
    this.datos.set(c.id, this.copia(c));
  }
  async buscarPorId(id: string) {
    const c = this.datos.get(id);
    return c ? this.copia(c) : null;
  }
  async buscarPorCita(citaId: string) {
    const c = [...this.datos.values()].find((x) => x.citaId === citaId);
    return c ? this.copia(c) : null;
  }
  async listarPorPaciente(pacienteId: string) {
    return [...this.datos.values()].filter((c) => c.pacienteId === pacienteId).sort((a, b) => b.fecha.getTime() - a.fecha.getTime()).map(this.copia);
  }
}

/** Lunes 12/10/2026 09:00 en Caracas. */
const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');

const consulta = (cambios: Partial<ContenidoConsulta> = {}): ContenidoConsulta => ({
  motivoConsulta: 'Control de hipertensión',
  enfermedadActual: 'Paciente con HTA en tratamiento, asintomática',
  signosVitales: { tensionArterial: '130/85', peso: 62, talla: 165 },
  examenFisico: 'Ruidos cardíacos rítmicos, sin soplos',
  listaProblemas: ['Hipertensión arterial'],
  impresionDiagnostica: ['Hipertensión arterial controlada'],
  plan: 'Continuar losartán 50 mg diario',
  ...cambios,
});

async function escenario() {
  const ctx = crearContexto();
  const { actor: paciente, perfil } = await ctx.pacienteTitular();
  const medico = await ctx.medicoVerificado('Valentina');
  const repos = { antecedentes: new AntecedentesMemoria(), consultas: new ConsultasMemoria() };
  const historia = new HistoriaClinicaService(
    repos.antecedentes,
    repos.consultas,
    ctx.politica,
    ctx.expediente,
    ctx.citas,
    ctx.perfiles,
    ctx.medicos,
    ctx.auditoria,
    ctx.notificador,
    ctx.reloj,
    new GeneradorPdfTexto(),
    ctx.almacenamiento,
  );
  const conceder = (categorias: CategoriaClinica[], escritura: boolean) =>
    ctx.expediente.concederAcceso(paciente, perfil.id, {
      medicoId: medico.medicoId!,
      categorias,
      validoHasta: sumarDias(ctx.reloj.ahora(), 30),
      escritura,
    });
  return { ctx, paciente, perfil, medico, historia, repos, conceder };
}

describe('HistoriaClinicaService (HU: historia clínica)', () => {
  it('el titular completa sus antecedentes (auto-reportados) y ve su historia sin auditoría', async () => {
    const { ctx, paciente, perfil, historia } = await escenario();
    await historia.actualizarAntecedentes(paciente, perfil.id, {
      grupoSanguineo: 'A+',
      alergicos: ['Penicilina'],
      ginecoObstetricos: { gestas: 1, partos: 1 },
    });
    const vista = await historia.obtener(paciente, perfil.id);
    expect(vista.antecedentes!.datos.alergicos).toEqual(['Penicilina']);
    expect(vista.antecedentes!.actualizadoPorMedicoId).toBeUndefined();
    expect(vista.puedeEditarAntecedentes).toBe(true);
    expect(vista.puedeRegistrarConsulta).toBe(false);
    expect(ctx.auditoria.entradas).toHaveLength(0);
  });

  it('un médico sin permiso no ve ni registra nada', async () => {
    const { perfil, medico, historia } = await escenario();
    await expect(historia.obtener(medico, perfil.id)).rejects.toThrow(AccesoDenegadoError);
    await expect(historia.registrarConsulta(medico, perfil.id, consulta())).rejects.toThrow('escritura');
  });

  it('el médico solo ve las secciones autorizadas y cada lectura queda auditada', async () => {
    const { ctx, paciente, perfil, medico, historia, conceder } = await escenario();
    await historia.actualizarAntecedentes(paciente, perfil.id, { alergicos: ['Látex'] });
    await conceder([CategoriaClinica.CONSULTAS], false);
    const vista = await historia.obtener(medico, perfil.id);
    expect(vista.antecedentes).toBeNull();
    expect(vista.consultas).toEqual([]);
    expect(vista.puedeRegistrarConsulta).toBe(false);
    expect(ctx.auditoria.entradas.map((e) => e.accion)).toContain('LEER_HISTORIA_CLINICA');
  });

  it('con escritura en Consultas el médico registra la consulta, se agrega a la línea de tiempo y se notifica al paciente', async () => {
    const { ctx, paciente, perfil, medico, historia, conceder } = await escenario();
    await conceder([CategoriaClinica.CONSULTAS, CategoriaClinica.DIAGNOSTICOS], true);
    const c = await historia.registrarConsulta(medico, perfil.id, consulta());
    expect(c.medicoId).toBe(medico.medicoId);
    expect(c.imc).toBe(22.8);

    const linea = await ctx.expediente.obtenerLineaDeTiempo(paciente, perfil.id, { tipo: TipoEvento.CONSULTA });
    expect(linea.items).toHaveLength(1);
    expect(linea.items[0].documentoOrigenId).toBe(c.id);
    expect(ctx.notificador.enviadas.some((n) => n.titulo === 'Nueva historia de consulta')).toBe(true);

    const vista = await historia.obtener(paciente, perfil.id);
    expect(vista.consultas.map((x) => x.id)).toEqual([c.id]);
  });

  it('el médico con escritura en Diagnósticos actualiza antecedentes y el paciente es notificado', async () => {
    const { ctx, perfil, medico, historia, conceder } = await escenario();
    await conceder([CategoriaClinica.DIAGNOSTICOS], true);
    const a = await historia.actualizarAntecedentes(medico, perfil.id, { patologicos: ['Diabetes tipo 2'] });
    expect(a.actualizadoPorMedicoId).toBe(medico.medicoId);
    expect(ctx.notificador.enviadas.some((n) => n.titulo === 'Antecedentes actualizados')).toBe(true);
  });

  it('el médico de la cita registra la historia aunque no tenga permiso, pero solo una vez por cita', async () => {
    const { ctx, paciente, perfil, medico, historia } = await escenario();
    const cita = await ctx.citas.agendar(paciente, {
      medicoId: medico.medicoId!,
      pacienteId: perfil.id,
      inicio: NUEVE_AM,
      modalidad: 'PRESENCIAL',
      motivo: 'Control',
    });
    const c = await historia.registrarConsulta(medico, perfil.id, { ...consulta(), citaId: cita.id });
    expect(c.citaId).toBe(cita.id);
    // Las citas registran su propio evento al marcarse atendidas: no se duplica en la línea de tiempo.
    const linea = await ctx.expediente.obtenerLineaDeTiempo(paciente, perfil.id, {});
    expect(linea.items).toHaveLength(0);
    await expect(historia.registrarConsulta(medico, perfil.id, { ...consulta(), citaId: cita.id })).rejects.toThrow(ConflictoError);

    const otro = await ctx.medicoVerificado('Daniel');
    await expect(historia.registrarConsulta(otro, perfil.id, { ...consulta(), citaId: cita.id })).rejects.toThrow('no pertenece');
  });

  it('solo el autor corrige la consulta y dentro de las 24 horas', async () => {
    const { ctx, perfil, medico, historia, conceder } = await escenario();
    await conceder([CategoriaClinica.CONSULTAS], true);
    const c = await historia.registrarConsulta(medico, perfil.id, consulta());
    const corregida = await historia.corregirConsulta(medico, perfil.id, c.id, consulta({ plan: 'Aumentar a 100 mg' }));
    expect(corregida.plan).toBe('Aumentar a 100 mg');
    const otro = await ctx.medicoVerificado('Daniel');
    await expect(historia.corregirConsulta(otro, perfil.id, c.id, consulta())).rejects.toThrow(AccesoDenegadoError);
    ctx.reloj.avanzarHoras(25);
    await expect(historia.corregirConsulta(medico, perfil.id, c.id, consulta())).rejects.toThrow('24 horas');
  });

  it('exporta la historia clínica en PDF con una URL firmada', async () => {
    const { paciente, perfil, historia } = await escenario();
    await historia.actualizarAntecedentes(paciente, perfil.id, { alergicos: ['Penicilina'] });
    const url = await historia.exportarPdf(paciente, perfil.id);
    expect(typeof url).toBe('string');
    expect(url.length).toBeGreaterThan(0);
  });
});
