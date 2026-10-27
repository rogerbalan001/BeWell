import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Notificador } from '../../../shared/application/notificador';
import { formatearFechaLocal } from '../../../shared/domain/fechas';
import { DIA_MS, HORA_MS, Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Medico, ZONA_HORARIA_POR_DEFECTO } from '../../medicos/domain/medico';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { ANTICIPOS_CITA_HORAS, DIAS_RECORDATORIO_ORDEN, enVentana, tomasDelTratamiento } from '../domain/planificacion';
import { CambiosPreferencias, PreferenciasRecordatorio, TipoRecordatorio } from '../domain/preferencias-recordatorio';
import { PreferenciasRecordatorioRepository, RegistroEnviosRepository } from '../domain/repositorios';
import { FuentesRecordatorio } from './fuentes-recordatorio';

/** El worker corre cada 5 minutos y revisa los últimos 15: si se salta una ejecución, no se pierde ningún recordatorio. */
export const VENTANA_WORKER_MS = 15 * 60_000;
/** Un récipe deja de generar recordatorios después de este tiempo (tratamientos largos incluidos). */
const DURACION_MAXIMA_TRATAMIENTO_MS = 120 * DIA_MS;
const DIAS_PROXIMOS = 7;
const MAXIMO_PROXIMOS = 40;

/** Un recordatorio calculado: todavía no enviado (worker) o por venir (vista "próximos"). */
export interface RecordatorioProgramado {
  /** Identifica el recordatorio de forma única (idempotencia del envío). */
  clave: string;
  tipo: TipoRecordatorio;
  pacienteId: string;
  pacienteNombre: string;
  programadoPara: Date;
  titulo: string;
  mensaje: string;
  datos: Record<string, string>;
}

/**
 * «Control» Recordatorios (HU-5: recordatorios de citas, medicamentos y exámenes).
 *
 * - Citas confirmadas: 24 h y 1 h antes.
 * - Medicamentos: una por toma, según la frecuencia y duración del récipe.
 * - Exámenes: si la orden sigue pendiente 1, 3 y 7 días después de indicada.
 *
 * No guarda recordatorios futuros: los calcula a partir de las citas, récipes y
 * órdenes vigentes. Así, si una cita se cancela o una orden se completa, el
 * recordatorio simplemente deja de existir. El envío usa la bandeja de
 * notificaciones (el canal push FCM/APNs se conecta detrás del mismo puerto).
 */
@Injectable()
export class RecordatoriosService {
  private readonly logger = new Logger(RecordatoriosService.name);

  constructor(
    private readonly fuentes: FuentesRecordatorio,
    private readonly preferencias: PreferenciasRecordatorioRepository,
    private readonly envios: RegistroEnviosRepository,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
  ) {}

  // ---------- Preferencias (criterio 3: activar o desactivar cada tipo) ----------

  async obtenerPreferencias(actor: Actor): Promise<PreferenciasRecordatorio> {
    return (await this.preferencias.buscar(actor.id)) ?? PreferenciasRecordatorio.porDefecto(actor.id, this.reloj.ahora());
  }

  async actualizarPreferencias(actor: Actor, cambios: CambiosPreferencias): Promise<PreferenciasRecordatorio> {
    const preferencias = await this.obtenerPreferencias(actor);
    preferencias.actualizar(cambios, this.reloj.ahora());
    await this.preferencias.guardar(preferencias);
    return preferencias;
  }

  // ---------- Próximos recordatorios del usuario (sus perfiles y los de su familia) ----------

  async proximos(actor: Actor, pacienteId?: string): Promise<RecordatorioProgramado[]> {
    const perfiles = await this.perfiles.listarPerfiles(actor.id);
    const ids = pacienteId ? perfiles.filter((p) => p.id === pacienteId).map((p) => p.id) : perfiles.map((p) => p.id);
    if (!ids.length) return [];
    const ahora = this.reloj.ahora();
    const preferencias = await this.obtenerPreferencias(actor);
    const lista = await this.programados(ahora, new Date(ahora.getTime() + DIAS_PROXIMOS * DIA_MS), ids);
    return lista
      .filter((r) => preferencias.permite(r.tipo))
      .sort((a, b) => a.programadoPara.getTime() - b.programadoPara.getTime())
      .slice(0, MAXIMO_PROXIMOS);
  }

  // ---------- Worker de envío ----------

  /** Envía los recordatorios cuya hora llegó. Devuelve cuántos envió (útil en pruebas). */
  @Cron(CronExpression.EVERY_5_MINUTES)
  async enviarPendientes(): Promise<number> {
    const ahora = this.reloj.ahora();
    let enviados = 0;
    let candidatos: RecordatorioProgramado[];
    try {
      candidatos = await this.programados(new Date(ahora.getTime() - VENTANA_WORKER_MS), ahora);
    } catch (e) {
      this.logger.error(`No se pudieron calcular los recordatorios: ${(e as Error).message}`);
      return 0;
    }
    const preferenciasPorUsuario = new Map<string, PreferenciasRecordatorio>();
    for (const r of candidatos) {
      try {
        const usuarioId = await this.perfiles.titularDe(r.pacienteId);
        let preferencias = preferenciasPorUsuario.get(usuarioId);
        if (!preferencias) {
          preferencias = (await this.preferencias.buscar(usuarioId)) ?? PreferenciasRecordatorio.porDefecto(usuarioId, ahora);
          preferenciasPorUsuario.set(usuarioId, preferencias);
        }
        if (!preferencias.permite(r.tipo)) continue;
        if (!(await this.envios.registrarSiNuevo(r.clave, ahora))) continue;
        await this.notificador.notificar({ usuarioId, tipo: 'RECORDATORIO', titulo: r.titulo, mensaje: r.mensaje, datos: r.datos });
        enviados++;
      } catch (e) {
        this.logger.warn(`No se pudo enviar el recordatorio ${r.clave}: ${(e as Error).message}`);
      }
    }
    return enviados;
  }

  // ---------- Cálculo ----------

  /** Recordatorios con hora en (desde, hasta]. */
  private async programados(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<RecordatorioProgramado[]> {
    const [citas, recipes, ordenes] = await Promise.all([
      this.recordatoriosDeCitas(desde, hasta, pacienteIds),
      this.recordatoriosDeMedicamentos(desde, hasta, pacienteIds),
      this.recordatoriosDeOrdenes(desde, hasta, pacienteIds),
    ]);
    const todos = [...citas, ...recipes, ...ordenes];
    const perfiles = new Map((await this.perfiles.obtenerVarios(todos.map((r) => r.pacienteId))).map((p) => [p.id, p]));
    return todos.map((r) => personalizar(r, perfiles.get(r.pacienteId)));
  }

  private async recordatoriosDeCitas(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<RecordatorioProgramado[]> {
    const resultado: RecordatorioProgramado[] = [];
    for (const horas of ANTICIPOS_CITA_HORAS) {
      const citas = await this.fuentes.citasConfirmadasEntre(
        new Date(desde.getTime() + horas * HORA_MS),
        new Date(hasta.getTime() + horas * HORA_MS),
        pacienteIds,
      );
      const medicos = await this.mapaMedicos(citas.map((c) => c.medicoId));
      for (const c of citas) {
        const medico = medicos.get(c.medicoId);
        const cuando = formatearFechaLocal(c.inicio, medico?.zonaHorariaMin ?? ZONA_HORARIA_POR_DEFECTO);
        const virtual = c.modalidad === 'VIRTUAL';
        resultado.push({
          clave: `cita:${c.id}:${horas}h`,
          tipo: TipoRecordatorio.CITAS,
          pacienteId: c.pacienteId,
          pacienteNombre: '',
          programadoPara: new Date(c.inicio.getTime() - horas * HORA_MS),
          titulo: horas === 24 ? '{Tu} cita es mañana' : '{Tu} cita es en 1 hora',
          mensaje:
            `Consulta con ${medico?.nombreCompleto ?? 'tu médico'} el ${cuando}` +
            (virtual ? ' (en línea). Entra a la app unos minutos antes.' : ' (presencial).') +
            (horas === 24 ? ' Si no puedes asistir, cancela desde la app según la política del médico.' : ''),
          datos: { tipo: TipoRecordatorio.CITAS, citaId: c.id, pacienteId: c.pacienteId },
        });
      }
    }
    return resultado;
  }

  private async recordatoriosDeMedicamentos(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<RecordatorioProgramado[]> {
    const recipes = await this.fuentes.recipesVigentes(new Date(desde.getTime() - DURACION_MAXIMA_TRATAMIENTO_MS), pacienteIds);
    const resultado: RecordatorioProgramado[] = [];
    for (const r of recipes) {
      r.items.forEach((item, indice) => {
        const tomas = tomasDelTratamiento(r.emitidoEn, item);
        tomas.forEach((toma, n) => {
          if (!enVentana(toma, desde, hasta)) return;
          const presentacion = item.presentacion ? ` (${item.presentacion})` : '';
          resultado.push({
            clave: `toma:${r.id}:${indice}:${toma.toISOString()}`,
            tipo: TipoRecordatorio.MEDICAMENTOS,
            pacienteId: r.pacienteId,
            pacienteNombre: '',
            programadoPara: toma,
            titulo: `{Medicamento}: ${item.medicamento}`,
            mensaje: `${item.medicamento}${presentacion}: ${item.dosis}, ${formatearFechaLocal(toma, ZONA_HORARIA_POR_DEFECTO)}. Toma ${n + 1} de ${tomas.length}.`,
            datos: { tipo: TipoRecordatorio.MEDICAMENTOS, recipeId: r.id, pacienteId: r.pacienteId },
          });
        });
      });
    }
    return resultado;
  }

  private async recordatoriosDeOrdenes(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<RecordatorioProgramado[]> {
    const masLejano = Math.max(...DIAS_RECORDATORIO_ORDEN);
    const ordenes = await this.fuentes.ordenesPendientes(new Date(desde.getTime() - masLejano * DIA_MS), pacienteIds);
    const resultado: RecordatorioProgramado[] = [];
    for (const o of ordenes) {
      for (const dias of DIAS_RECORDATORIO_ORDEN) {
        const cuando = new Date(o.creadaEn.getTime() + dias * DIA_MS);
        if (!enVentana(cuando, desde, hasta)) continue;
        resultado.push({
          clave: `orden:${o.id}:${dias}d`,
          tipo: TipoRecordatorio.EXAMENES,
          pacienteId: o.pacienteId,
          pacienteNombre: '',
          programadoPara: cuando,
          titulo: '{Tienes} exámenes pendientes',
          mensaje: `Hace ${dias === 1 ? '1 día' : `${dias} días`} te indicaron: ${o.examenes.join(', ')}. Cuando tengas los resultados, súbelos a la app.`,
          datos: { tipo: TipoRecordatorio.EXAMENES, solicitudId: o.id, pacienteId: o.pacienteId },
        });
      }
    }
    return resultado;
  }

  private async mapaMedicos(ids: string[]): Promise<Map<string, Medico>> {
    if (!ids.length) return new Map();
    return new Map((await this.medicos.obtenerVarios([...new Set(ids)])).map((m) => [m.id, m]));
  }
}

/**
 * Ajusta el texto según el perfil: "Tu cita es mañana" para el titular y
 * "La cita de Lucas es mañana" cuando el recordatorio es de un hijo o padre.
 */
function personalizar(r: RecordatorioProgramado, perfil?: PerfilPaciente): RecordatorioProgramado {
  const propio = !perfil || perfil.esTitular;
  const nombre = perfil?.nombres ?? '';
  const titulo = r.titulo
    .replace('{Tu} cita', propio ? 'Tu cita' : `La cita de ${nombre}`)
    .replace('{Medicamento}', propio ? 'Hora de tu medicamento' : `Medicamento de ${nombre}`)
    .replace('{Tienes}', propio ? 'Tienes' : `${nombre} tiene`);
  const mensaje = propio ? r.mensaje : r.mensaje.replace('te indicaron', `le indicaron a ${nombre}`);
  return { ...r, pacienteNombre: perfil?.nombreCompleto ?? '', titulo, mensaje };
}
