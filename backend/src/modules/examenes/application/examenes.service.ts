import { Injectable, Logger } from '@nestjs/common';
import { AlmacenamientoArchivos } from '../../../shared/application/almacenamiento-archivos';
import { Notificador } from '../../../shared/application/notificador';
import { RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { AccesoDenegadoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { CitasService } from '../../citas/application/citas.service';
import { ExpedienteService } from '../../expediente/application/expediente.service';
import { PoliticaAccesoExpediente } from '../../expediente/application/politica-acceso-expediente';
import { CategoriaClinica, TipoEvento } from '../../expediente/domain/categoria-clinica';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { ExamenMedico, ResultadoAnalito } from '../domain/examen-medico';
import { ExamenRepository, SolicitudExamenRepository } from '../domain/repositorios';
import { EstadoSolicitud, SolicitudExamen } from '../domain/solicitud-examen';
import { ServicioOcr } from './servicio-ocr';

export interface ArchivoExamen {
  contenido: Buffer;
  tipoMime: string;
  nombreOriginal: string;
}

/**
 * «Control» ExamenesService. HU: solicitar exámenes desde la app y recibir
 * los resultados en el expediente; subir fotos o PDF y extraer valores.
 */
@Injectable()
export class ExamenesService {
  private readonly logger = new Logger(ExamenesService.name);

  constructor(
    private readonly examenes: ExamenRepository,
    private readonly solicitudes: SolicitudExamenRepository,
    private readonly ocr: ServicioOcr,
    private readonly almacenamiento: AlmacenamientoArchivos,
    private readonly politica: PoliticaAccesoExpediente,
    private readonly expediente: ExpedienteService,
    private readonly citas: CitasService,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly notificador: Notificador,
    private readonly auditoria: RegistroAuditoria,
    private readonly reloj: Reloj,
  ) {}

  // ---------- Solicitudes (orden médica) ----------

  async solicitar(
    actor: Actor,
    datos: { pacienteId: string; examenes: string[]; indicaciones?: string; citaId?: string },
  ): Promise<SolicitudExamen> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede solicitar exámenes');
    if (datos.citaId) {
      const cita = await this.citas.obtenerPorId(datos.citaId);
      if (cita.medicoId !== actor.medicoId || cita.pacienteId !== datos.pacienteId) {
        throw new AccesoDenegadoError('La cita indicada no corresponde a este paciente');
      }
    } else {
      await this.politica.asegurarEscritura(actor, datos.pacienteId, CategoriaClinica.LABORATORIOS);
    }
    const solicitud = SolicitudExamen.crear({ ...datos, medicoId: actor.medicoId }, this.reloj.ahora());
    await this.solicitudes.guardar(solicitud);

    const medico = await this.medicos.obtener(actor.medicoId);
    await this.expediente.registrarEvento({
      pacienteId: datos.pacienteId,
      tipo: TipoEvento.SOLICITUD_EXAMEN,
      fecha: solicitud.creadaEn,
      titulo: `Orden de exámenes (${solicitud.examenes.length})`,
      resumen: `${solicitud.examenes.join(', ')}${solicitud.indicaciones ? `. Indicaciones: ${solicitud.indicaciones}` : ''}`,
      medicoId: medico.id,
      autorUsuarioId: actor.id,
      documentoOrigenId: solicitud.id,
      detalles: { estado: solicitud.estado },
    });
    await this.notificador.notificar({
      usuarioId: await this.perfiles.titularDe(datos.pacienteId),
      tipo: 'EXAMEN',
      titulo: 'Nueva orden de exámenes',
      mensaje: `${medico.nombreCompleto} te indicó: ${solicitud.examenes.join(', ')}. Cuando tengas los resultados, súbelos a la app.`,
      datos: { solicitudId: solicitud.id, pacienteId: datos.pacienteId },
    });
    return solicitud;
  }

  /** El médico que indicó la orden la anula mientras siga pendiente; se avisa al paciente. */
  async anularSolicitud(actor: Actor, solicitudId: string, motivo: string): Promise<SolicitudExamen> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede anular órdenes de exámenes');
    const solicitud = await this.obtenerSolicitud(solicitudId);
    solicitud.anular(actor.medicoId, motivo, this.reloj.ahora());
    await this.solicitudes.guardar(solicitud);
    await this.expediente.actualizarEventoDeDocumento(solicitud.id, TipoEvento.SOLICITUD_EXAMEN, {
      estado: solicitud.estado,
      motivoAnulacion: solicitud.motivoAnulacion ?? '',
    });
    const medico = await this.medicos.obtener(actor.medicoId);
    await this.notificador.notificar({
      usuarioId: await this.perfiles.titularDe(solicitud.pacienteId),
      tipo: 'EXAMEN',
      titulo: 'Orden de exámenes anulada',
      mensaje: `${medico.nombreCompleto} anuló la orden de ${solicitud.examenes.join(', ')}. Motivo: ${solicitud.motivoAnulacion}. Ya no necesitas hacerte esos exámenes.`,
      datos: { solicitudId: solicitud.id, pacienteId: solicitud.pacienteId },
    });
    return solicitud;
  }

  async listarSolicitudes(actor: Actor, pacienteId?: string): Promise<SolicitudExamen[]> {
    if (actor.medicoId) {
      const propias = await this.solicitudes.listarPorMedico(actor.medicoId);
      return pacienteId ? propias.filter((s) => s.pacienteId === pacienteId) : propias;
    }
    if (!pacienteId) throw new ReglaNegocioError('Indica el paciente');
    await this.perfiles.asegurarGestion(actor, pacienteId);
    return this.solicitudes.listarPorPaciente(pacienteId);
  }

  // ---------- Carga y extracción ----------

  async cargar(
    actor: Actor,
    datos: { pacienteId: string; titulo: string; solicitudId?: string; fechaExamen?: Date },
    archivo: ArchivoExamen,
  ): Promise<ExamenMedico> {
    await this.asegurarCarga(actor, datos.pacienteId);
    const solicitud = datos.solicitudId ? await this.obtenerSolicitud(datos.solicitudId) : undefined;
    if (solicitud && solicitud.pacienteId !== datos.pacienteId) throw new ReglaNegocioError('La orden no corresponde al paciente');
    if (solicitud?.estado === EstadoSolicitud.ANULADA) throw new ReglaNegocioError('Esa orden fue anulada por el médico; sube el examen sin asociarlo a la orden');

    const guardado = await this.almacenamiento.guardar('examenes', archivo.contenido, archivo.tipoMime, archivo.nombreOriginal);
    const examen = ExamenMedico.cargar(
      {
        pacienteId: datos.pacienteId,
        solicitudId: solicitud?.id,
        titulo: datos.titulo,
        fechaExamen: datos.fechaExamen,
        archivoRef: guardado.ruta,
        tipoMime: guardado.tipoMime,
        nombreArchivo: guardado.nombreOriginal,
        tamanoBytes: guardado.tamanoBytes,
        cargadoPorUsuarioId: actor.id,
      },
      this.reloj.ahora(),
    );

    // Degradación controlada: si el OCR falla, el examen queda como archivo adjunto.
    try {
      const resultados = await this.ocr.extraer(
        { contenido: archivo.contenido, tipoMime: archivo.tipoMime, nombre: archivo.nombreOriginal },
        solicitud?.examenes ?? [datos.titulo],
      );
      examen.registrarExtraccion(resultados as ResultadoAnalito[] | null);
    } catch (e) {
      this.logger.warn(`OCR falló para el examen ${examen.id}: ${(e as Error).message}`);
      examen.registrarExtraccion(null);
    }
    await this.examenes.guardar(examen);

    await this.expediente.registrarEvento({
      pacienteId: datos.pacienteId,
      tipo: TipoEvento.EXAMEN,
      fecha: datos.fechaExamen ?? examen.cargadoEn,
      titulo: examen.titulo,
      resumen: `Resultado cargado (${examen.nombreArchivo}).`,
      medicoId: solicitud?.medicoId,
      autorUsuarioId: actor.id,
      documentoOrigenId: examen.id,
      detalles: { estadoExtraccion: examen.estadoExtraccion, tipoMime: examen.tipoMime },
    });

    if (solicitud) {
      solicitud.completar(examen.id, this.reloj.ahora());
      await this.solicitudes.guardar(solicitud);
      // La orden en la línea de tiempo deja de verse como "pendiente".
      await this.expediente.actualizarEventoDeDocumento(solicitud.id, TipoEvento.SOLICITUD_EXAMEN, { estado: solicitud.estado });
      const [medico, paciente] = await Promise.all([this.medicos.obtener(solicitud.medicoId), this.perfiles.obtener(datos.pacienteId)]);
      await this.notificador.notificar({
        usuarioId: medico.usuarioId,
        tipo: 'EXAMEN',
        titulo: 'Resultados disponibles',
        mensaje: `${paciente.nombreCompleto} cargó los resultados de su orden: ${solicitud.examenes.join(', ')}.`,
        datos: { solicitudId: solicitud.id, examenId: examen.id, pacienteId: paciente.id },
      });
    }
    return examen;
  }

  async confirmarResultados(
    actor: Actor,
    examenId: string,
    resultados: Omit<ResultadoAnalito, 'validadoPorMedico' | 'confianzaOcr'>[],
  ): Promise<ExamenMedico> {
    const examen = await this.obtenerExamen(examenId);
    await this.perfiles.asegurarGestion(actor, examen.pacienteId);
    examen.confirmarResultados(resultados);
    await this.examenes.guardar(examen);
    return examen;
  }

  async validarResultados(actor: Actor, examenId: string): Promise<ExamenMedico> {
    if (!actor.medicoId) throw new AccesoDenegadoError();
    const examen = await this.obtenerExamen(examenId);
    await this.politica.asegurarEscritura(actor, examen.pacienteId, CategoriaClinica.LABORATORIOS);
    examen.validarPorMedico(actor.medicoId);
    await this.examenes.guardar(examen);
    return examen;
  }

  // ---------- Consulta ----------

  async listar(actor: Actor, pacienteId: string): Promise<ExamenMedico[]> {
    const acceso = await this.politica.asegurarLecturaDe(actor, pacienteId, CategoriaClinica.LABORATORIOS);
    if (!acceso.esTitular) await this.auditar(actor, 'LISTAR_EXAMENES', undefined, pacienteId);
    return this.examenes.listarPorPaciente(pacienteId);
  }

  async obtener(actor: Actor, examenId: string): Promise<ExamenMedico> {
    const examen = await this.obtenerExamen(examenId);
    const acceso = await this.politica.asegurarLecturaDe(actor, examen.pacienteId, CategoriaClinica.LABORATORIOS);
    if (!acceso.esTitular) await this.auditar(actor, 'LEER_EXAMEN', examen.id, examen.pacienteId);
    return examen;
  }

  async urlArchivo(actor: Actor, examenId: string): Promise<string> {
    const examen = await this.obtener(actor, examenId);
    return this.almacenamiento.generarUrlLectura(examen.archivoRef, 300);
  }

  private async asegurarCarga(actor: Actor, pacienteId: string): Promise<void> {
    if (await this.perfiles.puedeGestionar(actor.id, pacienteId)) return;
    await this.politica.asegurarEscritura(actor, pacienteId, CategoriaClinica.LABORATORIOS);
  }

  private async obtenerExamen(id: string): Promise<ExamenMedico> {
    const examen = await this.examenes.buscarPorId(id);
    if (!examen) throw new NoEncontradoError('Examen', id);
    return examen;
  }

  private async obtenerSolicitud(id: string): Promise<SolicitudExamen> {
    const solicitud = await this.solicitudes.buscarPorId(id);
    if (!solicitud) throw new NoEncontradoError('Orden de exámenes', id);
    return solicitud;
  }

  private auditar(actor: Actor, accion: string, recursoId: string | undefined, pacienteId: string): Promise<void> {
    return this.auditoria.registrar({ actorId: actor.id, rolActor: RolUsuario.MEDICO, accion, recurso: 'examen', recursoId, pacienteId });
  }
}
