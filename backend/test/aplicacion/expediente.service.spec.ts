import { AccesoDenegadoError } from '../../src/shared/domain/errores';
import { sumarDias } from '../../src/shared/domain/reloj';
import { CategoriaClinica, TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { EstadoReferencia } from '../../src/modules/expediente/domain/referencia-especialista';
import { crearContexto } from '../support/contexto';

async function escenario() {
  const ctx = crearContexto();
  const { actor: paciente, perfil } = await ctx.pacienteTitular();
  const medico = await ctx.medicoVerificado('Valentina');
  const base = ctx.reloj.ahora();
  const eventos: [TipoEvento, number, string][] = [
    [TipoEvento.CIRUGIA, 400, 'Apendicectomía'],
    [TipoEvento.VACUNA, 200, 'Influenza'],
    [TipoEvento.CONSULTA, 100, 'Chequeo anual'],
    [TipoEvento.EXAMEN, 50, 'Perfil lipídico'],
    [TipoEvento.NOTA_SALUD_MENTAL, 10, 'Sesión de terapia'],
  ];
  for (const [tipo, dias, titulo] of eventos) {
    await ctx.expediente.registrarEvento({ pacienteId: perfil.id, tipo, fecha: sumarDias(base, -dias), titulo, resumen: titulo });
  }
  return { ctx, paciente, perfil, medico };
}

describe('ExpedienteService (HU: dueño de mi expediente y línea de tiempo)', () => {
  it('el titular ve todo, del evento más reciente al más antiguo, y puede filtrar por tipo', async () => {
    const { ctx, paciente, perfil } = await escenario();
    const linea = await ctx.expediente.obtenerLineaDeTiempo(paciente, perfil.id, {});
    expect(linea.items.map((e) => e.titulo)).toEqual(['Sesión de terapia', 'Perfil lipídico', 'Chequeo anual', 'Influenza', 'Apendicectomía']);
    const vacunas = await ctx.expediente.obtenerLineaDeTiempo(paciente, perfil.id, { tipo: TipoEvento.VACUNA });
    expect(vacunas.items).toHaveLength(1);
    expect(ctx.auditoria.entradas).toHaveLength(0);
  });

  it('un médico sin permiso no accede', async () => {
    const { ctx, perfil, medico } = await escenario();
    await expect(ctx.expediente.obtenerLineaDeTiempo(medico, perfil.id, {})).rejects.toThrow(AccesoDenegadoError);
  });

  it('un médico autorizado ve solo las secciones concedidas y el acceso queda auditado', async () => {
    const { ctx, paciente, perfil, medico } = await escenario();
    await ctx.expediente.concederAcceso(paciente, perfil.id, {
      medicoId: medico.medicoId!,
      categorias: [CategoriaClinica.LABORATORIOS, CategoriaClinica.CONSULTAS],
      validoHasta: sumarDias(ctx.reloj.ahora(), 30),
      escritura: false,
    });
    const linea = await ctx.expediente.obtenerLineaDeTiempo(medico, perfil.id, {});
    expect(linea.items.map((e) => e.titulo)).toEqual(['Perfil lipídico', 'Chequeo anual']);
    expect(ctx.auditoria.entradas[0].accion).toBe('LEER_LINEA_TIEMPO');
    await expect(
      ctx.expediente.agregarEvento(medico, perfil.id, { tipo: TipoEvento.CONSULTA, titulo: 'Nota', resumen: '', fecha: ctx.reloj.ahora() }),
    ).rejects.toThrow('escritura');
  });

  it('la revocación y el vencimiento cortan el acceso de inmediato', async () => {
    const { ctx, paciente, perfil, medico } = await escenario();
    const permiso = await ctx.expediente.concederAcceso(paciente, perfil.id, {
      medicoId: medico.medicoId!,
      categorias: [CategoriaClinica.CONSULTAS],
      validoHasta: sumarDias(ctx.reloj.ahora(), 2),
      escritura: true,
    });
    await ctx.expediente.agregarEvento(medico, perfil.id, { tipo: TipoEvento.CONSULTA, titulo: 'Control', resumen: 'Estable', fecha: ctx.reloj.ahora() });
    ctx.reloj.avanzarHoras(49);
    await expect(ctx.expediente.obtenerLineaDeTiempo(medico, perfil.id, {})).rejects.toThrow(AccesoDenegadoError);

    ctx.reloj.avanzarHoras(-49);
    await ctx.expediente.revocarAcceso(paciente, permiso.id);
    await expect(ctx.expediente.obtenerLineaDeTiempo(medico, perfil.id, {})).rejects.toThrow(AccesoDenegadoError);
  });

  it('referencia: el paciente aprueba y el especialista recibe acceso y notificación', async () => {
    const { ctx, paciente, perfil, medico } = await escenario();
    const especialista = await ctx.medicoVerificado('Daniel');
    await ctx.expediente.concederAcceso(paciente, perfil.id, {
      medicoId: medico.medicoId!,
      categorias: [CategoriaClinica.CONSULTAS, CategoriaClinica.SALUD_MENTAL],
      validoHasta: sumarDias(ctx.reloj.ahora(), 30),
      escritura: false,
    });
    const ref = await ctx.referencias.referir(medico, { pacienteId: perfil.id, medicoDestinoId: especialista.medicoId!, motivo: 'Palpitaciones' });
    await expect(ctx.expediente.obtenerLineaDeTiempo(especialista, perfil.id, {})).rejects.toThrow(AccesoDenegadoError);

    const aprobada = await ctx.referencias.aprobar(paciente, ref.id);
    expect(aprobada.estado).toBe(EstadoReferencia.APROBADA);
    const acceso = await ctx.politica.evaluar(especialista, perfil.id);
    expect(acceso.categorias).toEqual([CategoriaClinica.CONSULTAS]);
    expect(ctx.notificador.enviadas.some((n) => n.usuarioId === especialista.id && n.tipo === 'REFERENCIA')).toBe(true);
  });

  it('exporta el expediente en PDF (HU: exportar mi expediente completo)', async () => {
    const { ctx, paciente, perfil } = await escenario();
    const url = await ctx.expediente.exportarPdf(paciente, perfil.id);
    const ruta = ctx.almacenamiento.resolverTokenLectura(url.split('/archivos/')[1]);
    const archivo = await ctx.almacenamiento.leer(ruta);
    const texto = archivo.contenido.toString('latin1');
    expect(archivo.tipoMime).toBe('application/pdf');
    expect(texto.startsWith('%PDF-1.4')).toBe(true);
    expect(texto).toContain('Sof\xEDa Morales');
    expect(texto).toContain('Apendicectom\xEDa');
    expect(texto).toContain('%%EOF');
  });
});
