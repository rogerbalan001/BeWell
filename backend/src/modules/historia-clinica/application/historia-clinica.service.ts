import { Injectable } from '@nestjs/common';
import { AlmacenamientoArchivos } from '../../../shared/application/almacenamiento-archivos';
import { GeneradorPdf } from '../../../shared/application/generador-pdf';
import { Notificador } from '../../../shared/application/notificador';
import { RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { AccesoDenegadoError, ConflictoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { CitasService } from '../../citas/application/citas.service';
import { EstadoCita } from '../../citas/domain/cita';
import { ExpedienteService } from '../../expediente/application/expediente.service';
import { AccesoExpediente, PoliticaAccesoExpediente } from '../../expediente/application/politica-acceso-expediente';
import { CategoriaClinica, TipoEvento } from '../../expediente/domain/categoria-clinica';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { AntecedentesClinicos, DatosAntecedentes } from '../domain/antecedentes-clinicos';
import { ConsultaClinica, ContenidoConsulta } from '../domain/consulta-clinica';
import { AntecedentesClinicosRepository, ConsultaClinicaRepository } from '../domain/repositorios';
import { lineasHistoriaPdf } from './historia-pdf';

/** Sección del expediente que protege los antecedentes. */
export const CATEGORIA_ANTECEDENTES = CategoriaClinica.DIAGNOSTICOS;
/** Sección del expediente que protege las historias de cada consulta. */
export const CATEGORIA_CONSULTAS = CategoriaClinica.CONSULTAS;

export interface HistoriaClinicaVista {
  paciente: PerfilPaciente;
  acceso: AccesoExpediente;
  /** null si el actor no tiene acceso a la sección de antecedentes. */
  antecedentes: AntecedentesClinicos | null;
  /** Vacío si el actor no tiene acceso a la sección de consultas. */
  consultas: ConsultaClinica[];
  puedeEditarAntecedentes: boolean;
  puedeRegistrarConsulta: boolean;
}

export type DatosNuevaConsulta = ContenidoConsulta & { fecha?: Date; citaId?: string };

/**
 * «Control» HistoriaClinicaService. HU: historia clínica del paciente.
 * Antecedentes estables (anamnesis remota) + historia de cada consulta
 * (motivo, enfermedad actual, examen físico, impresión diagnóstica y plan).
 * Reutiliza la política de acceso del expediente: el titular ve y edita todo;
 * un médico solo lo que el paciente autorizó.
 */
@Injectable()
export class HistoriaClinicaService {
  constructor(
    private readonly antecedentes: AntecedentesClinicosRepository,
    private readonly consultas: ConsultaClinicaRepository,
    private readonly politica: PoliticaAccesoExpediente,
    private readonly expediente: ExpedienteService,
    private readonly citas: CitasService,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly auditoria: RegistroAuditoria,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
    private readonly pdf: GeneradorPdf,
    private readonly almacenamiento: AlmacenamientoArchivos,
  ) {}

  async obtener(actor: Actor, pacienteId: string): Promise<HistoriaClinicaVista> {
    const acceso = await this.politica.asegurarLectura(actor, pacienteId);
    const paciente = await this.perfiles.obtener(pacienteId);
    const veAntecedentes = acceso.categorias.includes(CATEGORIA_ANTECEDENTES);
    const veConsultas = acceso.categorias.includes(CATEGORIA_CONSULTAS);
    const [antecedentes, consultas] = await Promise.all([
      veAntecedentes ? this.obtenerOCrearAntecedentes(pacienteId) : Promise.resolve(null),
      veConsultas ? this.consultas.listarPorPaciente(pacienteId) : Promise.resolve([]),
    ]);
    await this.auditar(actor, acceso, 'LEER_HISTORIA_CLINICA', 'historia_clinica', antecedentes?.id, pacienteId);
    return {
      paciente,
      acceso,
      antecedentes,
      consultas,
      puedeEditarAntecedentes: acceso.categoriasEscritura.includes(CATEGORIA_ANTECEDENTES),
      puedeRegistrarConsulta: !!actor.medicoId && !acceso.esTitular && acceso.categoriasEscritura.includes(CATEGORIA_CONSULTAS),
    };
  }

  /** El titular (dato auto-reportado) o un médico con escritura en Diagnósticos actualiza los antecedentes. */
  async actualizarAntecedentes(actor: Actor, pacienteId: string, datos: Partial<DatosAntecedentes>): Promise<AntecedentesClinicos> {
    const acceso = await this.politica.asegurarEscritura(actor, pacienteId, CATEGORIA_ANTECEDENTES);
    const paciente = await this.perfiles.obtener(pacienteId);
    const antecedentes = await this.obtenerOCrearAntecedentes(pacienteId);
    antecedentes.actualizar(
      datos,
      { usuarioId: actor.id, medicoId: acceso.esTitular ? undefined : actor.medicoId },
      paciente.sexo === 'F',
      this.reloj.ahora(),
    );
    await this.antecedentes.guardar(antecedentes);
    await this.auditar(actor, acceso, 'ACTUALIZAR_ANTECEDENTES', 'historia_clinica', antecedentes.id, pacienteId);
    if (!acceso.esTitular) {
      await this.notificador.notificar({
        usuarioId: await this.perfiles.titularDe(pacienteId),
        tipo: 'EXPEDIENTE',
        titulo: 'Antecedentes actualizados',
        mensaje: `Tu médico actualizó los antecedentes de la historia clínica de ${paciente.nombreCompleto}.`,
        datos: { pacienteId },
      });
    }
    return antecedentes;
  }

  /**
   * Un médico registra la historia de una consulta. Con `citaId` basta con ser
   * el médico de esa cita (confirmada o atendida); sin cita necesita permiso
   * de escritura en la sección Consultas.
   */
  async registrarConsulta(actor: Actor, pacienteId: string, datos: DatosNuevaConsulta): Promise<ConsultaClinica> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede registrar la historia de una consulta');
    const ahora = this.reloj.ahora();
    let acceso: AccesoExpediente;
    let fecha = datos.fecha ?? ahora;
    if (datos.citaId) {
      const cita = await this.citas.obtenerPorId(datos.citaId);
      if (cita.medicoId !== actor.medicoId) throw new AccesoDenegadoError('La cita no pertenece a este médico');
      if (cita.pacienteId !== pacienteId) throw new ReglaNegocioError('La cita no corresponde a este paciente');
      if (cita.estado !== EstadoCita.CONFIRMADA && cita.estado !== EstadoCita.ATENDIDA) {
        throw new ReglaNegocioError('Solo se registra la historia de citas confirmadas o atendidas');
      }
      if (await this.consultas.buscarPorCita(cita.id)) throw new ConflictoError('Esta cita ya tiene una historia clínica registrada');
      acceso = await this.politica.evaluar(actor, pacienteId);
      fecha = datos.fecha ?? (cita.inicio < ahora ? cita.inicio : ahora);
    } else {
      acceso = await this.politica.asegurarEscritura(actor, pacienteId, CATEGORIA_CONSULTAS);
    }

    const consulta = ConsultaClinica.registrar(
      { ...datos, pacienteId, medicoId: actor.medicoId, autorUsuarioId: actor.id, citaId: datos.citaId, fecha },
      ahora,
    );
    await this.consultas.guardar(consulta);

    // Las citas ya dejan su evento al marcarse atendidas; las consultas sin cita se agregan a la línea de tiempo.
    if (!consulta.citaId) {
      await this.expediente.registrarEvento({
        pacienteId,
        tipo: TipoEvento.CONSULTA,
        fecha: consulta.fecha,
        titulo: `Consulta: ${consulta.motivoConsulta}`.slice(0, 150),
        resumen: `Impresión diagnóstica: ${consulta.impresionDiagnostica.join('; ')}\nPlan: ${consulta.plan}`,
        medicoId: actor.medicoId,
        autorUsuarioId: actor.id,
        documentoOrigenId: consulta.id,
        detalles: { historiaClinica: 'true' },
      });
    }
    await this.auditar(actor, acceso, 'REGISTRAR_CONSULTA', 'consulta_clinica', consulta.id, pacienteId);
    await this.notificador.notificar({
      usuarioId: await this.perfiles.titularDe(pacienteId),
      tipo: 'EXPEDIENTE',
      titulo: 'Nueva historia de consulta',
      mensaje: `Se registró la historia clínica de tu consulta: "${consulta.motivoConsulta}".`,
      datos: { pacienteId, consultaId: consulta.id },
    });
    return consulta;
  }

  async obtenerConsulta(actor: Actor, pacienteId: string, consultaId: string): Promise<ConsultaClinica> {
    const consulta = await this.buscarConsulta(pacienteId, consultaId);
    const acceso = await this.politica.asegurarLecturaDe(actor, pacienteId, CATEGORIA_CONSULTAS);
    await this.auditar(actor, acceso, 'LEER_CONSULTA', 'consulta_clinica', consulta.id, pacienteId);
    return consulta;
  }

  /** El médico autor corrige la historia dentro de las primeras 24 h. */
  async corregirConsulta(actor: Actor, pacienteId: string, consultaId: string, contenido: ContenidoConsulta): Promise<ConsultaClinica> {
    const consulta = await this.buscarConsulta(pacienteId, consultaId);
    if (consulta.medicoId !== actor.medicoId) throw new AccesoDenegadoError('Solo el médico que registró la consulta puede corregirla');
    consulta.corregir(actor.medicoId, contenido, this.reloj.ahora());
    await this.consultas.guardar(consulta);
    const acceso = await this.politica.evaluar(actor, pacienteId);
    await this.auditar(actor, acceso, 'CORREGIR_CONSULTA', 'consulta_clinica', consulta.id, pacienteId);
    return consulta;
  }

  /** Historia clínica en PDF (solo las secciones autorizadas). URL firmada de 5 minutos. */
  async exportarPdf(actor: Actor, pacienteId: string): Promise<string> {
    const vista = await this.obtener(actor, pacienteId);
    const { paciente, antecedentes, consultas, acceso } = vista;
    const medicos = new Map((await this.medicos.obtenerVarios(consultas.map((c) => c.medicoId))).map((m) => [m.id, m]));
    const ahora = this.reloj.ahora();
    const fecha = (d: Date) => d.toISOString().slice(0, 10);
    const lineas = lineasHistoriaPdf({
      paciente,
      antecedentes,
      consultas,
      verConsultas: acceso.categorias.includes(CATEGORIA_CONSULTAS),
      parcial: acceso.esTitular ? undefined : `Exportación parcial: secciones autorizadas (${acceso.categorias.join(', ')}).`,
      medicos,
      ahora,
    });

    const contenido = this.pdf.generar(`Historia clínica ${paciente.nombreCompleto}`, lineas);
    const nombre = `historia-clinica-${paciente.nombres.toLowerCase().replace(/\s+/g, '-')}-${fecha(ahora)}.pdf`;
    const guardado = await this.almacenamiento.guardar('exportaciones', contenido, 'application/pdf', nombre);
    await this.auditar(actor, acceso, 'EXPORTAR_HISTORIA_CLINICA', 'historia_clinica', antecedentes?.id, pacienteId);
    return this.almacenamiento.generarUrlLectura(guardado.ruta, 300);
  }

  private async obtenerOCrearAntecedentes(pacienteId: string): Promise<AntecedentesClinicos> {
    const existente = await this.antecedentes.buscarPorPaciente(pacienteId);
    if (existente) return existente;
    const nuevos = AntecedentesClinicos.abrir(pacienteId, this.reloj.ahora());
    await this.antecedentes.guardar(nuevos);
    return nuevos;
  }

  private async buscarConsulta(pacienteId: string, consultaId: string): Promise<ConsultaClinica> {
    const consulta = await this.consultas.buscarPorId(consultaId);
    if (!consulta || consulta.pacienteId !== pacienteId) throw new NoEncontradoError('Consulta clínica', consultaId);
    return consulta;
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
