import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

export enum EstadoReferencia {
  PENDIENTE_APROBACION = 'PENDIENTE_APROBACION',
  APROBADA = 'APROBADA',
  RECHAZADA = 'RECHAZADA',
}

export interface PropsReferencia {
  id: string;
  pacienteId: string;
  medicoOrigenId: string;
  medicoDestinoId: string;
  especialidadDestino: string;
  /** Nota clínica para el especialista (cifrada en la base de datos). */
  motivo: string;
  estado: EstadoReferencia;
  fecha: Date;
  respondidaEn?: Date;
}

/**
 * «Entity» ReferenciaEspecialista. El paciente debe aprobar que se comparta
 * su expediente con el especialista (HU referencias).
 */
export class ReferenciaEspecialista implements PropsReferencia {
  id: string;
  pacienteId: string;
  medicoOrigenId: string;
  medicoDestinoId: string;
  especialidadDestino: string;
  motivo: string;
  estado: EstadoReferencia;
  fecha: Date;
  respondidaEn?: Date;

  constructor(props: PropsReferencia) {
    Object.assign(this, props);
  }

  static emitir(datos: Omit<PropsReferencia, 'id' | 'estado' | 'fecha' | 'respondidaEn'>, ahora: Date): ReferenciaEspecialista {
    asegurar(datos.medicoOrigenId !== datos.medicoDestinoId, 'No puedes referirte un paciente a ti mismo');
    asegurar(datos.motivo?.trim(), 'Incluye una nota clínica para el especialista');
    return new ReferenciaEspecialista({ ...datos, id: generarId(), estado: EstadoReferencia.PENDIENTE_APROBACION, fecha: ahora });
  }

  aprobar(ahora: Date): void {
    this.exigirPendiente();
    this.estado = EstadoReferencia.APROBADA;
    this.respondidaEn = ahora;
  }

  rechazar(ahora: Date): void {
    this.exigirPendiente();
    this.estado = EstadoReferencia.RECHAZADA;
    this.respondidaEn = ahora;
  }

  private exigirPendiente(): void {
    if (this.estado !== EstadoReferencia.PENDIENTE_APROBACION) throw new ReglaNegocioError('La referencia ya fue respondida');
  }
}
