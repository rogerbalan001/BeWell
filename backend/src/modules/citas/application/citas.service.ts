import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Notificador } from '../../../shared/application/notificador';
import { AccesoDenegadoError, asegurar, ConflictoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { formatearFechaLocal } from '../../../shared/domain/fechas';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { ReferenciasService } from '../../expediente/application/referencias.service';
import { ExpedienteService } from '../../expediente/application/expediente.service';
import { TipoEvento } from '../../expediente/domain/categoria-clinica';
import { EstadoReferencia } from '../../expediente/domain/referencia-especialista';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Franja } from '../../medicos/domain/bloque-horario';
import { Medico, Modalidad } from '../../medicos/domain/medico';
import { PagosService } from '../../pagos/application/pagos.service';
import { EstadoPago } from '../../pagos/domain/pago';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { Cita, EstadoCita, Parte } from '../domain/cita';
import { CitaRepository, FiltrosCitas } from '../domain/cita.repository';

export interface SolicitudAgendar {
  medicoId: string;
  pacienteId: string;
  inicio: Date;
  modalidad: Modalidad;
  motivo: string;
}

export interface SolicitudPropuesta {
  pacienteId: string;
  medicoId?: string;
  inicio: Date;
  modalidad: Modalidad;
  motivo?: string;
  citaOrigenId?: string;
  referenciaId?: string;
}

export const DIAS_MAXIMOS_DISPONIBILIDAD = 31;

/**
 * «Control» CitasService. Disponibilidad, agendamiento con retención del pago,
 * cancelación con política, atención y citas de seguimiento con aceptación mutua.
 */
@Injectable()
export class CitasService {
  private readonly logger = new Logger(CitasService.name);

  constructor(
    private readonly citas: CitaRepository,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
    private readonly pagos: PagosService,
    private readonly expediente: ExpedienteService,
    private readonly referencias: ReferenciasService,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
  ) {}

  async consultarDisponibilidad(medicoId: string, desde: Date | undefined, dias: number): Promise<Franja[]> {
    const medico = await this.medicos.obtenerPublico(medicoId);
    const ahora = this.reloj.ahora();
    const inicio = desde && desde > ahora ? desde : ahora;
    const franjas = medico.generarFranjas(inicio, Math.min(Math.max(dias, 1), DIAS_MAXIMOS_DISPONIBILIDAD));
    if (!franjas.length) return [];
    const ocupadas = await this.citas.buscarOcupadas(medicoId, franjas[0].inicio, franjas[franjas.length - 1].fin);
    return franjas.filter((f) => !ocupadas.some((c) => c.inicio < f.fin && c.fin > f.inicio));
  }

  /** HU: agendar una consulta directamente con el especialista elegido. */
  async agendar(actor: Actor, s: SolicitudAgendar): Promise<Cita> {
    const paciente = await this.perfiles.asegurarGestion(actor, s.pacienteId);
    const medico = await this.medicos.obtenerPublico(s.medicoId);
    const franja = await this.validarFranja(medico, s.inicio, s.modalidad);
    const cita = Cita.agendar(
      {
        pacienteId: paciente.id,
        medicoId: medico.id,
        agendadaPorUsuarioId: actor.id,
        inicio: franja.inicio,
        fin: franja.fin,
        modalidad: s.modalidad,
        motivo: s.motivo,
        monto: medico.tarifaConsulta,
        moneda: medico.moneda,
        politica: medico.politicaCancelacion,
      },
      this.reloj.ahora(),
    );
    await this.citas.guardar(cita); // el índice único parcial evita la doble reserva en carreras
    await this.cobrar(cita);
    if (cita.estado === EstadoCita.CONFIRMADA) {
      await this.notificador.notificar({
        usuarioId: medico.usuarioId,
        tipo: 'CITA',
        titulo: 'Nueva cita agendada',
        mensaje: `${paciente.nombreCompleto} reservó para el ${formatearFechaLocal(cita.inicio, medico.zonaHorariaMin)} (${cita.modalidad.toLowerCase()}).`,
        datos: { citaId: cita.id },
      });
    }
    return cita;
  }

  async cancelar(actor: Actor, citaId: string, motivo: string): Promise<{ cita: Cita; reembolso: number }> {
    const cita = await this.obtenerPorId(citaId);
    const parte = await this.parteDelActor(actor, cita);
    const reembolso = cita.cancelar(parte, motivo, this.reloj.ahora());
    await this.citas.guardar(cita);
    await this.pagos.reembolsar(cita.id, reembolso, `Cancelación por ${parte.toLowerCase()}: ${cita.motivoCancelacion}`);
    await this.notificarOtraParte(cita, parte, 'Cita cancelada', `La cita del ${await this.fechaCita(cita)} fue cancelada. Motivo: ${cita.motivoCancelacion}.`);
    return { cita, reembolso };
  }

  async simularCancelacion(actor: Actor, citaId: string): Promise<number> {
    const cita = await this.obtenerPorId(citaId);
    const parte = await this.parteDelActor(actor, cita);
    return parte === 'MEDICO' && cita.estado === EstadoCita.CONFIRMADA ? cita.monto : cita.simularReembolso(this.reloj.ahora());
  }

  /** El médico marca la consulta como atendida: inicia la retención de 24 h y se registra en el expediente. */
  async marcarAtendida(actor: Actor, citaId: string, datos: { notaClinica?: string; diagnosticos?: string[] }): Promise<Cita> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede marcar la cita como atendida');
    const cita = await this.obtenerPorId(citaId);
    const ahora = this.reloj.ahora();
    cita.marcarAtendida(actor.medicoId, ahora);
    await this.citas.guardar(cita);
    await this.pagos.programarLiberacion(cita.id);

    const medico = await this.medicos.obtener(cita.medicoId);
    await this.expediente.registrarEvento({
      pacienteId: cita.pacienteId,
      tipo: TipoEvento.CONSULTA,
      fecha: cita.inicio,
      titulo: `Consulta de ${medico.especialidades[0]}`,
      resumen: datos.notaClinica?.trim() || `Motivo de consulta: ${cita.motivo || 'no especificado'}`,
      medicoId: medico.id,
      autorUsuarioId: actor.id,
      documentoOrigenId: cita.id,
      detalles: { modalidad: cita.modalidad, motivo: cita.motivo },
    });
    for (const diagnostico of (datos.diagnosticos ?? []).map((d) => d.trim()).filter(Boolean)) {
      await this.expediente.registrarEvento({
        pacienteId: cita.pacienteId,
        tipo: TipoEvento.DIAGNOSTICO,
        fecha: cita.inicio,
        titulo: diagnostico,
        resumen: `Diagnóstico emitido en consulta de ${medico.especialidades[0]}`,
        medicoId: medico.id,
        autorUsuarioId: actor.id,
        documentoOrigenId: cita.id,
      });
    }
    await this.notificador.notificar({
      usuarioId: await this.perfiles.titularDe(cita.pacienteId),
      tipo: 'CITA',
      titulo: 'Consulta completada',
      mensaje: `Tu consulta con ${medico.nombreCompleto} quedó registrada en tu expediente. Ya puedes dejar tu reseña. Si hubo algún problema, repórtalo en las próximas 24 h.`,
      datos: { citaId: cita.id },
    });
    return cita;
  }

  async marcarNoAsistio(actor: Actor, citaId: string): Promise<Cita> {
    if (!actor.medicoId) throw new AccesoDenegadoError();
    const cita = await this.obtenerPorId(citaId);
    cita.marcarNoAsistio(actor.medicoId, this.reloj.ahora());
    await this.citas.guardar(cita);
    await this.pagos.programarLiberacion(cita.id);
    return cita;
  }

  /** HU pagos: el paciente reporta un problema; el pago queda retenido hasta revisión. */
  async reportarProblema(actor: Actor, citaId: string, motivo: string): Promise<void> {
    const cita = await this.obtenerPorId(citaId);
    if ((await this.parteDelActor(actor, cita)) !== 'PACIENTE') throw new AccesoDenegadoError('Solo el paciente puede reportar un problema');
    asegurar(cita.estado === EstadoCita.ATENDIDA, 'Solo se pueden reportar problemas de citas atendidas');
    await this.pagos.abrirDisputa(cita.id, motivo);
  }

  // ---------- Citas de seguimiento (HU: aceptación de ambas partes) ----------

  async proponer(actor: Actor, s: SolicitudPropuesta): Promise<Cita> {
    let parte: Parte;
    let medico: Medico;
    if (actor.medicoId) {
      parte = 'MEDICO';
      medico = await this.medicos.obtener(actor.medicoId);
      await this.validarRelacionMedico(medico.id, s);
    } else {
      parte = 'PACIENTE';
      await this.perfiles.asegurarGestion(actor, s.pacienteId);
      if (!s.medicoId || !s.citaOrigenId) throw new ReglaNegocioError('Indica el médico y la consulta previa');
      medico = await this.medicos.obtenerPublico(s.medicoId);
      await this.validarCitaOrigen(s.citaOrigenId, medico.id, s.pacienteId);
    }
    const franja = await this.validarFranja(medico, s.inicio, s.modalidad);
    const cita = Cita.proponer(
      {
        pacienteId: s.pacienteId,
        medicoId: medico.id,
        agendadaPorUsuarioId: actor.id,
        inicio: franja.inicio,
        fin: franja.fin,
        modalidad: s.modalidad,
        motivo: s.motivo ?? 'Consulta de seguimiento',
        monto: medico.tarifaConsulta,
        moneda: medico.moneda,
        politica: medico.politicaCancelacion,
        propuestaPor: parte,
        citaOrigenId: s.citaOrigenId,
        referenciaId: s.referenciaId,
      },
      this.reloj.ahora(),
    );
    await this.citas.guardar(cita);
    await this.notificarOtraParte(
      cita,
      parte,
      'Propuesta de cita',
      `${parte === 'MEDICO' ? medico.nombreCompleto : 'Tu paciente'} propone una cita para el ${formatearFechaLocal(cita.inicio, medico.zonaHorariaMin)}. Tienes 48 h para aceptarla.`,
    );
    return cita;
  }

  async aceptarPropuesta(actor: Actor, citaId: string): Promise<Cita> {
    const cita = await this.obtenerPorId(citaId);
    const parte = await this.parteDelActor(actor, cita);
    cita.aceptarPropuesta(parte, this.reloj.ahora());
    if (await this.citas.existeSolapamiento(cita.medicoId, cita.inicio, cita.fin, cita.id)) {
      throw new ConflictoError('La franja ya no está disponible');
    }
    await this.citas.guardar(cita);
    await this.cobrar(cita);
    await this.notificarOtraParte(cita, parte, 'Propuesta aceptada', `La cita del ${await this.fechaCita(cita)} quedó ${cita.estado === EstadoCita.CONFIRMADA ? 'confirmada' : 'cancelada por pago rechazado'}.`);
    return cita;
  }

  async rechazarPropuesta(actor: Actor, citaId: string): Promise<Cita> {
    const cita = await this.obtenerPorId(citaId);
    const parte = await this.parteDelActor(actor, cita);
    cita.rechazarPropuesta(parte, this.reloj.ahora());
    await this.citas.guardar(cita);
    await this.notificarOtraParte(cita, parte, 'Propuesta rechazada', `La propuesta de cita del ${await this.fechaCita(cita)} fue rechazada.`);
    return cita;
  }

  /** Worker: cancela las propuestas sin respuesta en 48 h y avisa a ambas partes. */
  @Cron(CronExpression.EVERY_10_MINUTES)
  async expirarPropuestas(): Promise<number> {
    const ahora = this.reloj.ahora();
    const vencidas = await this.citas.buscarPropuestasVencidas(ahora);
    for (const cita of vencidas) {
      if (!cita.expirarPropuesta(ahora)) continue;
      await this.citas.guardar(cita);
      const mensaje = `La propuesta de cita del ${await this.fechaCita(cita)} se canceló por no recibir respuesta en 48 horas.`;
      await this.notificarOtraParte(cita, 'PACIENTE', 'Propuesta vencida', mensaje);
      await this.notificarOtraParte(cita, 'MEDICO', 'Propuesta vencida', mensaje);
    }
    if (vencidas.length) this.logger.log(`Propuestas vencidas: ${vencidas.length}`);
    return vencidas.length;
  }

  // ---------- Consultas ----------

  async listar(actor: Actor, filtros: FiltrosCitas & { pacienteId?: string }): Promise<Cita[]> {
    if (actor.medicoId) return this.citas.listarPorMedico(actor.medicoId, filtros);
    const ids = filtros.pacienteId
      ? [(await this.perfiles.asegurarGestion(actor, filtros.pacienteId)).id]
      : (await this.perfiles.listarPerfiles(actor.id)).map((p) => p.id);
    return this.citas.listarPorPacientes(ids, filtros);
  }

  async obtenerParaActor(actor: Actor, citaId: string): Promise<Cita> {
    const cita = await this.obtenerPorId(citaId);
    await this.parteDelActor(actor, cita);
    return cita;
  }

  async obtenerPorId(citaId: string): Promise<Cita> {
    const cita = await this.citas.buscarPorId(citaId);
    if (!cita) throw new NoEncontradoError('Cita', citaId);
    return cita;
  }

  async parteDelActor(actor: Actor, cita: Cita): Promise<Parte> {
    if (actor.medicoId && actor.medicoId === cita.medicoId) return 'MEDICO';
    if (await this.perfiles.puedeGestionar(actor.id, cita.pacienteId)) return 'PACIENTE';
    throw new AccesoDenegadoError('Esta cita no te pertenece');
  }

  // ---------- Auxiliares ----------

  private async cobrar(cita: Cita): Promise<void> {
    const pago = await this.pagos.retenerPago({
      citaId: cita.id,
      pacienteId: cita.pacienteId,
      medicoId: cita.medicoId,
      monto: cita.monto,
      moneda: cita.moneda,
    });
    if (pago.estado === EstadoPago.RETENIDO) cita.confirmarPago();
    else cita.cancelar('SISTEMA', 'Pago rechazado por la pasarela', this.reloj.ahora());
    await this.citas.guardar(cita);
  }

  private async validarFranja(medico: Medico, inicio: Date, modalidad: Modalidad): Promise<Franja> {
    if (!medico.modalidades.includes(modalidad)) throw new ReglaNegocioError(`El médico no ofrece consultas ${modalidad.toLowerCase()}`);
    const franja = medico.franjaQueIniciaEn(inicio);
    if (!franja) throw new ReglaNegocioError('El horario elegido no está en la agenda del médico');
    if (franja.inicio <= this.reloj.ahora()) throw new ReglaNegocioError('El horario elegido ya pasó');
    if (await this.citas.existeSolapamiento(medico.id, franja.inicio, franja.fin)) {
      throw new ConflictoError('Ese horario acaba de ser reservado. Elige otro.');
    }
    return franja;
  }

  private async validarCitaOrigen(citaOrigenId: string, medicoId: string, pacienteId: string): Promise<void> {
    const origen = await this.obtenerPorId(citaOrigenId);
    if (origen.estado !== EstadoCita.ATENDIDA || origen.medicoId !== medicoId || origen.pacienteId !== pacienteId) {
      throw new ReglaNegocioError('El seguimiento requiere una consulta atendida previa con este médico');
    }
  }

  private async validarRelacionMedico(medicoId: string, s: SolicitudPropuesta): Promise<void> {
    if (s.citaOrigenId) return this.validarCitaOrigen(s.citaOrigenId, medicoId, s.pacienteId);
    if (s.referenciaId) {
      const ref = await this.referencias.obtener(s.referenciaId);
      if (ref.estado !== EstadoReferencia.APROBADA || ref.medicoDestinoId !== medicoId || ref.pacienteId !== s.pacienteId) {
        throw new ReglaNegocioError('La referencia no está aprobada para este paciente');
      }
      return;
    }
    throw new ReglaNegocioError('Indica la consulta previa o la referencia que origina la propuesta');
  }

  private async notificarOtraParte(cita: Cita, quienActua: Parte | 'SISTEMA', titulo: string, mensaje: string): Promise<void> {
    const usuarioId =
      quienActua === 'MEDICO'
        ? await this.perfiles.titularDe(cita.pacienteId)
        : (await this.medicos.obtener(cita.medicoId)).usuarioId;
    await this.notificador.notificar({ usuarioId, tipo: 'CITA', titulo, mensaje, datos: { citaId: cita.id } });
  }

  private async fechaCita(cita: Cita): Promise<string> {
    const medico = await this.medicos.obtener(cita.medicoId);
    return formatearFechaLocal(cita.inicio, medico.zonaHorariaMin);
  }
}
