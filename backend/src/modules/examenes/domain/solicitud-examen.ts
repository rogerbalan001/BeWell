import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

export enum EstadoSolicitud {
  PENDIENTE = 'PENDIENTE',
  COMPLETADA = 'COMPLETADA',
  ANULADA = 'ANULADA',
}

export interface PropsSolicitud {
  id: string;
  pacienteId: string;
  medicoId: string;
  citaId?: string;
  examenes: string[];
  /** Cifradas a nivel de campo. */
  indicaciones: string;
  estado: EstadoSolicitud;
  examenResultadoIds: string[];
  creadaEn: Date;
  completadaEn?: Date;
  motivoAnulacion?: string;
  anuladaEn?: Date;
}

/** «Entity» SolicitudExamen (orden médica, equivalente a ServiceRequest en FHIR). */
export class SolicitudExamen implements PropsSolicitud {
  id: string;
  pacienteId: string;
  medicoId: string;
  citaId?: string;
  examenes: string[];
  indicaciones: string;
  estado: EstadoSolicitud;
  examenResultadoIds: string[];
  creadaEn: Date;
  completadaEn?: Date;
  motivoAnulacion?: string;
  anuladaEn?: Date;

  constructor(props: PropsSolicitud) {
    Object.assign(this, props);
  }

  static crear(datos: { pacienteId: string; medicoId: string; citaId?: string; examenes: string[]; indicaciones?: string }, ahora: Date): SolicitudExamen {
    const examenes = [...new Set(datos.examenes.map((e) => e.trim()).filter(Boolean))];
    asegurar(examenes.length > 0, 'Selecciona al menos un examen del catálogo');
    return new SolicitudExamen({
      id: generarId(),
      pacienteId: datos.pacienteId,
      medicoId: datos.medicoId,
      citaId: datos.citaId,
      examenes,
      indicaciones: datos.indicaciones?.trim() ?? '',
      estado: EstadoSolicitud.PENDIENTE,
      examenResultadoIds: [],
      creadaEn: ahora,
    });
  }

  /** Al cargar los resultados la orden pasa a "completada". */
  completar(examenId: string, ahora: Date): void {
    if (this.estado === EstadoSolicitud.ANULADA) throw new ReglaNegocioError('La orden fue anulada');
    this.examenResultadoIds = [...new Set([...this.examenResultadoIds, examenId])];
    if (this.estado === EstadoSolicitud.PENDIENTE) {
      this.estado = EstadoSolicitud.COMPLETADA;
      this.completadaEn = ahora;
    }
  }

  /** El médico que la indicó puede anular una orden mientras siga pendiente. */
  anular(medicoId: string, motivo: string, ahora: Date): void {
    asegurar(this.medicoId === medicoId, 'Solo el médico que indicó la orden puede anularla');
    if (this.estado !== EstadoSolicitud.PENDIENTE) {
      throw new ReglaNegocioError(
        this.estado === EstadoSolicitud.COMPLETADA
          ? 'La orden ya tiene resultados cargados; no se puede anular'
          : 'La orden ya estaba anulada',
      );
    }
    const texto = motivo?.trim() ?? '';
    asegurar(texto.length >= 5, 'Indica el motivo de la anulación (al menos 5 caracteres)');
    this.estado = EstadoSolicitud.ANULADA;
    this.motivoAnulacion = texto;
    this.anuladaEn = ahora;
  }
}
