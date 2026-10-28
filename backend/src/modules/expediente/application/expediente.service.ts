import { Injectable } from '@nestjs/common';
import { AlmacenamientoArchivos } from '../../../shared/application/almacenamiento-archivos';
import { GeneradorPdf, LineaPdf } from '../../../shared/application/generador-pdf';
import { Notificador } from '../../../shared/application/notificador';
import { RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { asegurar, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { CategoriaClinica, categoriaDe, TipoEvento } from '../domain/categoria-clinica';
import { EventoClinico, PropsEventoClinico } from '../domain/evento-clinico';
import { ExpedienteClinico } from '../domain/expediente-clinico';
import { PermisoAcceso } from '../domain/permiso-acceso';
import { EventoClinicoRepository, ExpedienteRepository, PermisoAccesoRepository } from '../domain/repositorios';
import { AccesoExpediente, PoliticaAccesoExpediente } from './politica-acceso-expediente';

export type NuevoEvento = Omit<PropsEventoClinico, 'id' | 'expedienteId' | 'categoria' | 'creadoEn' | 'detalles'> & {
  categoria?: CategoriaClinica;
  detalles?: Record<string, string>;
};

/** Tipos que solo se generan desde su módulo de origen (récipes, exámenes, referencias). */
const TIPOS_DE_SISTEMA = [TipoEvento.RECETA, TipoEvento.SOLICITUD_EXAMEN, TipoEvento.REFERENCIA, TipoEvento.EXAMEN];

/**
 * «Control» ExpedienteService. Línea de tiempo, control de privacidad
 * (conceder / revocar permisos) y registro de eventos clínicos.
 */
@Injectable()
export class ExpedienteService {
  constructor(
    private readonly expedientes: ExpedienteRepository,
    private readonly eventos: EventoClinicoRepository,
    private readonly permisos: PermisoAccesoRepository,
    private readonly politica: PoliticaAccesoExpediente,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly auditoria: RegistroAuditoria,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
    private readonly pdf: GeneradorPdf,
    private readonly almacenamiento: AlmacenamientoArchivos,
  ) {}

  async obtenerOCrear(pacienteId: string): Promise<ExpedienteClinico> {
    const existente = await this.expedientes.buscarPorPaciente(pacienteId);
    if (existente) return existente;
    const expediente = ExpedienteClinico.abrir(pacienteId, this.reloj.ahora());
    await this.expedientes.guardar(expediente);
    return expediente;
  }

  async resumen(
    actor: Actor,
    pacienteId: string,
  ): Promise<{ expediente: ExpedienteClinico; paciente: PerfilPaciente; acceso: AccesoExpediente }> {
    const acceso = await this.politica.asegurarLectura(actor, pacienteId);
    const [expediente, paciente] = await Promise.all([this.obtenerOCrear(pacienteId), this.perfiles.obtener(pacienteId)]);
    await this.auditar(actor, acceso, 'LEER_RESUMEN', 'expediente', expediente.id, pacienteId);
    return { expediente, paciente, acceso };
  }

  async actualizarAntecedentes(actor: Actor, pacienteId: string, antecedentes: string[]): Promise<ExpedienteClinico> {
    await this.politica.asegurarEscritura(actor, pacienteId, CategoriaClinica.DIAGNOSTICOS);
    const expediente = await this.obtenerOCrear(pacienteId);
    expediente.actualizarAntecedentes(antecedentes, this.reloj.ahora());
    await this.expedientes.guardar(expediente);
    return expediente;
  }

  /** HU: línea de tiempo del más reciente al más antiguo, filtrable por tipo. */
  async obtenerLineaDeTiempo(
    actor: Actor,
    pacienteId: string,
    filtros: { tipo?: TipoEvento; pagina?: number; tamano?: number },
  ): Promise<{ items: EventoClinico[]; total: number; pagina: number; tamano: number; acceso: AccesoExpediente }> {
    const acceso = await this.politica.asegurarLectura(actor, pacienteId);
    const pagina = Math.max(1, filtros.pagina ?? 1);
    const tamano = Math.min(50, Math.max(1, filtros.tamano ?? 20));
    const categorias =
      filtros.tipo && !acceso.categorias.includes(categoriaDe(filtros.tipo)) ? [] : acceso.categorias;
    const { items, total } = categorias.length
      ? await this.eventos.listarPorPaciente(pacienteId, categorias, filtros.tipo, { pagina, tamano })
      : { items: [], total: 0 };
    await this.auditar(actor, acceso, 'LEER_LINEA_TIEMPO', 'expediente', undefined, pacienteId);
    return { items, total, pagina, tamano, acceso };
  }

  async obtenerEvento(actor: Actor, pacienteId: string, eventoId: string): Promise<EventoClinico> {
    const evento = await this.eventos.buscarPorId(eventoId);
    if (!evento || evento.pacienteId !== pacienteId) throw new NoEncontradoError('Evento clínico', eventoId);
    const acceso = await this.politica.asegurarLecturaDe(actor, pacienteId, evento.categoria);
    await this.auditar(actor, acceso, 'LEER_EVENTO', 'evento_clinico', evento.id, pacienteId);
    return evento;
  }

  /** Un médico autorizado (o el propio titular, como dato auto-reportado) agrega información. */
  async agregarEvento(
    actor: Actor,
    pacienteId: string,
    datos: { tipo: TipoEvento; titulo: string; resumen: string; fecha: Date; categoria?: CategoriaClinica; detalles?: Record<string, string> },
  ): Promise<EventoClinico> {
    if (TIPOS_DE_SISTEMA.includes(datos.tipo)) {
      throw new ReglaNegocioError(`Los eventos ${datos.tipo} se generan desde su módulo correspondiente`);
    }
    const categoria = datos.categoria ?? categoriaDe(datos.tipo);
    const acceso = await this.politica.asegurarEscritura(actor, pacienteId, categoria);
    const evento = await this.registrarEvento({
      ...datos,
      categoria,
      pacienteId,
      medicoId: acceso.esTitular ? undefined : actor.medicoId,
      autorUsuarioId: actor.id,
      detalles: acceso.esTitular ? { ...datos.detalles, autoReportado: 'true' } : datos.detalles,
    });
    if (!acceso.esTitular) {
      await this.notificador.notificar({
        usuarioId: await this.perfiles.titularDe(pacienteId),
        tipo: 'EXPEDIENTE',
        titulo: 'Nueva información en tu expediente',
        mensaje: `Se agregó "${evento.titulo}" a tu historial clínico.`,
        datos: { pacienteId, eventoId: evento.id },
      });
    }
    return evento;
  }

  /** Uso interno de otros módulos (citas, exámenes, récipes, referencias). */
  async registrarEvento(datos: NuevoEvento): Promise<EventoClinico> {
    const expediente = await this.obtenerOCrear(datos.pacienteId);
    const evento = EventoClinico.registrar({ ...datos, expedienteId: expediente.id }, this.reloj.ahora());
    await this.eventos.guardar(evento);
    return evento;
  }

  /** Uso interno: refleja en la línea de tiempo un cambio del documento de origen (p. ej. orden completada o anulada). */
  async actualizarEventoDeDocumento(documentoOrigenId: string, tipo: TipoEvento, detalles: Record<string, string>): Promise<void> {
    await this.eventos.actualizarDetallesPorDocumento(documentoOrigenId, tipo, detalles);
  }

  /**
   * HU: el paciente puede exportar su expediente completo en PDF. Un médico
   * autorizado exporta solo las secciones permitidas. Devuelve una URL de
   * descarga firmada de 5 minutos.
   */
  async exportarPdf(actor: Actor, pacienteId: string): Promise<string> {
    const acceso = await this.politica.asegurarLectura(actor, pacienteId);
    const [expediente, paciente] = await Promise.all([this.obtenerOCrear(pacienteId), this.perfiles.obtener(pacienteId)]);
    const eventos: EventoClinico[] = [];
    for (let pagina = 1; pagina <= 20; pagina++) {
      const { items, total } = await this.eventos.listarPorPaciente(pacienteId, acceso.categorias, undefined, { pagina, tamano: 50 });
      eventos.push(...items);
      if (eventos.length >= total || !items.length) break;
    }
    const medicos = new Map(
      (await this.medicos.obtenerVarios(eventos.map((e) => e.medicoId).filter((x): x is string => !!x))).map((m) => [m.id, m]),
    );
    const ahora = this.reloj.ahora();
    const fecha = (d: Date) => d.toISOString().slice(0, 10);
    const lineas: LineaPdf[] = [
      { texto: 'Bewell - Expediente clínico digital', tamano: 18, negrita: true, color: 'primario' },
      { texto: `ID único EXP-${expediente.id.slice(-8).toUpperCase()} · generado el ${fecha(ahora)}`, color: 'tenue' },
      { texto: paciente.nombreCompleto, tamano: 15, negrita: true, espacioAntes: 12 },
      {
        texto: `Cédula: ${paciente.cedula ?? 'no registrada'} · Fecha de nacimiento: ${fecha(paciente.fechaNacimiento)} · Edad: ${paciente.edad(ahora)} años · Sexo: ${paciente.sexo}`,
      },
      ...(acceso.esTitular ? [] : [{ texto: `Exportación parcial: secciones autorizadas (${acceso.categorias.join(', ')}).`, color: 'tenue' as const }]),
      { texto: 'Antecedentes', tamano: 13, negrita: true, espacioAntes: 14 },
      ...(expediente.antecedentes.length ? expediente.antecedentes.map((a) => ({ texto: `- ${a}` })) : [{ texto: 'Sin antecedentes registrados.', color: 'tenue' as const }]),
      { texto: `Línea de tiempo (${eventos.length} eventos)`, tamano: 13, negrita: true, espacioAntes: 14 },
    ];
    for (const e of eventos) {
      const medico = e.medicoId ? medicos.get(e.medicoId) : undefined;
      lineas.push({ texto: `${fecha(e.fecha)} · ${e.tipo} · ${e.titulo}`, negrita: true, espacioAntes: 8 });
      if (medico) lineas.push({ texto: `${medico.nombreCompleto} (${medico.especialidades[0]})`, color: 'tenue' });
      if (e.resumen) lineas.push({ texto: e.resumen });
    }
    lineas.push({
      texto: 'Documento generado por Bewell. La información clínica es propiedad del paciente y su uso está sujeto a su consentimiento.',
      tamano: 8,
      color: 'tenue',
      espacioAntes: 20,
    });

    const contenido = this.pdf.generar(`Expediente ${paciente.nombreCompleto}`, lineas);
    const nombre = `expediente-${paciente.nombres.toLowerCase().replace(/\s+/g, '-')}-${fecha(ahora)}.pdf`;
    const guardado = await this.almacenamiento.guardar('exportaciones', contenido, 'application/pdf', nombre);
    await this.auditar(actor, acceso, 'EXPORTAR_PDF', 'expediente', expediente.id, pacienteId);
    return this.almacenamiento.generarUrlLectura(guardado.ruta, 300);
  }

  // ---------- Control de privacidad (HU: decidir qué médico ve qué parte y por cuánto tiempo) ----------

  async concederAcceso(
    actor: Actor,
    pacienteId: string,
    datos: { medicoId: string; categorias: CategoriaClinica[]; validoHasta: Date; escritura: boolean },
  ): Promise<PermisoAcceso> {
    await this.perfiles.asegurarGestion(actor, pacienteId);
    const medico = await this.medicos.obtenerPublico(datos.medicoId);
    const expediente = await this.obtenerOCrear(pacienteId);
    const permiso = PermisoAcceso.conceder(
      {
        expedienteId: expediente.id,
        pacienteId,
        medicoId: medico.id,
        categoriasPermitidas: datos.categorias,
        escritura: datos.escritura,
        validoHasta: datos.validoHasta,
        otorgadoPorUsuarioId: actor.id,
        origen: 'PACIENTE',
      },
      this.reloj.ahora(),
    );
    await this.permisos.guardar(permiso);
    const paciente = await this.perfiles.obtener(pacienteId);
    await this.notificador.notificar({
      usuarioId: medico.usuarioId,
      tipo: 'PERMISO',
      titulo: 'Nuevo acceso a expediente',
      mensaje: `${paciente.nombreCompleto} te dio acceso a su expediente hasta el ${datos.validoHasta.toISOString().slice(0, 10)}.`,
      datos: { pacienteId },
    });
    return permiso;
  }

  /** Concesión automática derivada de una referencia aprobada por el paciente. */
  async concederPorReferencia(
    pacienteId: string,
    medicoId: string,
    categorias: CategoriaClinica[],
    validoHasta: Date,
    otorgadoPor: string,
  ): Promise<PermisoAcceso> {
    const expediente = await this.obtenerOCrear(pacienteId);
    const permiso = PermisoAcceso.conceder(
      {
        expedienteId: expediente.id,
        pacienteId,
        medicoId,
        categoriasPermitidas: categorias,
        escritura: true,
        validoHasta,
        otorgadoPorUsuarioId: otorgadoPor,
        origen: 'REFERENCIA',
      },
      this.reloj.ahora(),
    );
    await this.permisos.guardar(permiso);
    return permiso;
  }

  async revocarAcceso(actor: Actor, permisoId: string): Promise<PermisoAcceso> {
    const permiso = await this.permisos.buscarPorId(permisoId);
    if (!permiso) throw new NoEncontradoError('Permiso', permisoId);
    await this.perfiles.asegurarGestion(actor, permiso.pacienteId);
    asegurar(!permiso.revocado, 'El permiso ya estaba revocado');
    permiso.revocar(this.reloj.ahora());
    await this.permisos.guardar(permiso);
    return permiso;
  }

  async listarPermisos(actor: Actor, pacienteId: string): Promise<PermisoAcceso[]> {
    await this.perfiles.asegurarGestion(actor, pacienteId);
    return this.permisos.listarPorPaciente(pacienteId);
  }

  /** Pacientes que autorizaron al médico (vista "Mis pacientes"). */
  async pacientesAutorizados(actor: Actor): Promise<{ paciente: PerfilPaciente; permisos: PermisoAcceso[] }[]> {
    if (!actor.medicoId) return [];
    const vigentes = await this.permisos.listarVigentesPorMedico(actor.medicoId, this.reloj.ahora());
    const pacientes = await this.perfiles.obtenerVarios(vigentes.map((p) => p.pacienteId));
    return pacientes.map((paciente) => ({ paciente, permisos: vigentes.filter((p) => p.pacienteId === paciente.id) }));
  }

  private async auditar(
    actor: Actor,
    acceso: AccesoExpediente,
    accion: string,
    recurso: string,
    recursoId: string | undefined,
    pacienteId: string,
  ): Promise<void> {
    if (acceso.esTitular) return; // solo se auditan accesos de terceros
    await this.auditoria.registrar({
      actorId: actor.id,
      rolActor: actor.roles.includes(RolUsuario.MEDICO) ? RolUsuario.MEDICO : actor.roles[0],
      accion,
      recurso,
      recursoId,
      pacienteId,
    });
  }
}
