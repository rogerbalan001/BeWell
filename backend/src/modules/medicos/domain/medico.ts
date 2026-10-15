import { Centavos } from '../../../shared/domain/dinero';
import { asegurar, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { aMinutos, BloqueHorario, Franja, validarBloques } from './bloque-horario';
import { CredencialProfesional, EstadoVerificacion, TipoCredencial, TIPOS_CREDENCIAL } from './credencial-profesional';
import { PoliticaCancelacion, TipoPolitica } from './politica-cancelacion';

export type Modalidad = 'PRESENCIAL' | 'VIRTUAL';

export interface PropsMedico {
  id: string;
  usuarioId: string;
  nombres: string;
  apellidos: string;
  especialidades: string[];
  tarifaConsulta: Centavos;
  moneda: string;
  estadoVerificacion: EstadoVerificacion;
  credenciales: CredencialProfesional[];
  politicaCancelacion: PoliticaCancelacion;
  horario: BloqueHorario[];
  modalidades: Modalidad[];
  direccionConsultorio?: string;
  biografia?: string;
  /** Desfase de la hora local del médico respecto a UTC, en minutos (Venezuela: -240). */
  zonaHorariaMin: number;
  calificacionPromedio: number;
  totalResenas: number;
  llaveFirmaId?: string;
  creadoEn: Date;
}

export const ZONA_HORARIA_POR_DEFECTO = -240;

/**
 * «Entity» Medico. Embebe sus credenciales, su política de cancelación y su
 * horario semanal. Solo aparece en el directorio cuando está APROBADO.
 */
export class Medico implements PropsMedico {
  id: string;
  usuarioId: string;
  nombres: string;
  apellidos: string;
  especialidades: string[];
  tarifaConsulta: Centavos;
  moneda: string;
  estadoVerificacion: EstadoVerificacion;
  credenciales: CredencialProfesional[];
  politicaCancelacion: PoliticaCancelacion;
  horario: BloqueHorario[];
  modalidades: Modalidad[];
  direccionConsultorio?: string;
  biografia?: string;
  zonaHorariaMin: number;
  calificacionPromedio: number;
  totalResenas: number;
  llaveFirmaId?: string;
  creadoEn: Date;

  constructor(props: PropsMedico) {
    Object.assign(this, props);
  }

  static registrar(
    usuarioId: string,
    datos: { nombres: string; apellidos: string; especialidades: string[]; tarifaConsulta: Centavos },
    ahora: Date,
  ): Medico {
    asegurar(datos.nombres?.trim() && datos.apellidos?.trim(), 'Nombre y apellido son obligatorios');
    asegurar(datos.especialidades?.length, 'Debe indicar al menos una especialidad');
    asegurar(datos.tarifaConsulta > 0, 'La tarifa de consulta debe ser mayor que cero');
    return new Medico({
      id: generarId(),
      usuarioId,
      nombres: datos.nombres.trim(),
      apellidos: datos.apellidos.trim(),
      especialidades: datos.especialidades.map((e) => e.trim()),
      tarifaConsulta: datos.tarifaConsulta,
      moneda: 'USD',
      estadoVerificacion: EstadoVerificacion.PENDIENTE,
      credenciales: [],
      politicaCancelacion: PoliticaCancelacion.porDefecto(),
      horario: [],
      modalidades: ['PRESENCIAL', 'VIRTUAL'],
      zonaHorariaMin: ZONA_HORARIA_POR_DEFECTO,
      calificacionPromedio: 0,
      totalResenas: 0,
      creadoEn: ahora,
    });
  }

  get nombreCompleto(): string {
    return `${this.nombres} ${this.apellidos}`;
  }

  estaVerificado(): boolean {
    return this.estadoVerificacion === EstadoVerificacion.APROBADO;
  }

  // ---------- Verificación profesional ----------

  /** Registra (o reemplaza) la credencial de un tipo; queda PENDIENTE de revisión. */
  registrarCredencial(tipo: TipoCredencial, numero: string, archivoRef: string, ahora: Date): CredencialProfesional {
    asegurar(TIPOS_CREDENCIAL.includes(tipo), `Tipo de credencial inválido: ${tipo}`);
    asegurar(numero?.trim(), 'El número de la credencial es obligatorio');
    const credencial: CredencialProfesional = {
      id: generarId(),
      tipo,
      numero: numero.trim(),
      archivoRef,
      estado: EstadoVerificacion.PENDIENTE,
      enviadaEn: ahora,
    };
    this.credenciales = [...this.credenciales.filter((c) => c.tipo !== tipo), credencial];
    this.recalcularEstado();
    return credencial;
  }

  aprobarCredencial(credencialId: string, adminId: string, ahora: Date): void {
    const c = this.credencialPendiente(credencialId);
    c.estado = EstadoVerificacion.APROBADO;
    c.revisadoPorId = adminId;
    c.fechaRevision = ahora;
    c.observaciones = undefined;
    this.recalcularEstado();
  }

  rechazarCredencial(credencialId: string, adminId: string, motivo: string, ahora: Date): void {
    asegurar(motivo?.trim(), 'Debe indicar el motivo del rechazo');
    const c = this.credencialPendiente(credencialId);
    c.estado = EstadoVerificacion.RECHAZADO;
    c.revisadoPorId = adminId;
    c.fechaRevision = ahora;
    c.observaciones = motivo.trim();
    this.recalcularEstado();
  }

  tieneCredencialesPendientes(): boolean {
    return this.credenciales.some((c) => c.estado === EstadoVerificacion.PENDIENTE);
  }

  /** APROBADO solo si título, colegiatura y cédula están aprobados; RECHAZADO si alguna se rechazó. */
  recalcularEstado(): EstadoVerificacion {
    if (this.credenciales.some((c) => c.estado === EstadoVerificacion.RECHAZADO)) {
      this.estadoVerificacion = EstadoVerificacion.RECHAZADO;
    } else if (
      TIPOS_CREDENCIAL.every((t) =>
        this.credenciales.some((c) => c.tipo === t && c.estado === EstadoVerificacion.APROBADO),
      )
    ) {
      this.estadoVerificacion = EstadoVerificacion.APROBADO;
    } else {
      this.estadoVerificacion = EstadoVerificacion.PENDIENTE;
    }
    return this.estadoVerificacion;
  }

  private credencialPendiente(id: string): CredencialProfesional {
    const c = this.credenciales.find((x) => x.id === id);
    if (!c) throw new NoEncontradoError('Credencial', id);
    if (c.estado !== EstadoVerificacion.PENDIENTE) throw new ReglaNegocioError('La credencial ya fue revisada');
    return c;
  }

  // ---------- Agenda ----------

  configurarHorario(bloques: BloqueHorario[], modalidades?: Modalidad[]): void {
    validarBloques(bloques);
    this.horario = bloques;
    if (modalidades) {
      asegurar(modalidades.length > 0, 'Debe ofrecer al menos una modalidad');
      this.modalidades = modalidades;
    }
  }

  configurarPolitica(tipo: TipoPolitica): void {
    this.politicaCancelacion = PoliticaCancelacion.desdeTipo(tipo);
  }

  /**
   * Franjas teóricas según el horario semanal, a partir de `desde` y por
   * `dias` días locales. No descuenta las citas ya reservadas (eso lo hace
   * el módulo de Citas).
   */
  generarFranjas(desde: Date, dias: number): Franja[] {
    const desfaseMs = this.zonaHorariaMin * 60_000;
    const localDesde = new Date(desde.getTime() + desfaseMs);
    const inicioDiaLocal = Date.UTC(localDesde.getUTCFullYear(), localDesde.getUTCMonth(), localDesde.getUTCDate());
    const franjas: Franja[] = [];
    for (let d = 0; d < dias; d++) {
      const diaLocalMs = inicioDiaLocal + d * 86_400_000;
      const diaSemana = new Date(diaLocalMs).getUTCDay();
      for (const b of this.horario.filter((x) => x.diaSemana === diaSemana)) {
        for (let m = aMinutos(b.horaInicio); m + b.duracionCitaMin <= aMinutos(b.horaFin); m += b.duracionCitaMin) {
          const inicio = new Date(diaLocalMs + m * 60_000 - desfaseMs);
          if (inicio.getTime() < desde.getTime()) continue;
          franjas.push({ inicio, fin: new Date(inicio.getTime() + b.duracionCitaMin * 60_000) });
        }
      }
    }
    return franjas.sort((a, b) => a.inicio.getTime() - b.inicio.getTime());
  }

  /** Devuelve la franja del horario que empieza exactamente en `inicio`, si existe. */
  franjaQueIniciaEn(inicio: Date): Franja | undefined {
    const inicioDia = new Date(inicio.getTime() - 86_400_000);
    return this.generarFranjas(inicioDia, 3).find((f) => f.inicio.getTime() === inicio.getTime());
  }

  actualizarCalificacion(promedio: number, total: number): void {
    this.calificacionPromedio = Math.round(promedio * 10) / 10;
    this.totalResenas = total;
  }
}
