import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { sumarDias } from '../../../shared/domain/reloj';

export const DIAS_EDICION_RESENA = 7;

export interface Calificaciones {
  puntualidad: number;
  trato: number;
  claridad: number;
  instalaciones: number;
}

export interface PropsResena extends Calificaciones {
  id: string;
  citaId: string;
  pacienteId: string;
  medicoId: string;
  autorUsuarioId: string;
  comentario?: string;
  publicadaEn: Date;
  editadaEn?: Date;
}

/**
 * «Entity» ResenaVerificada. Solo existe para una cita ATENDIDA (índice único
 * sobre citaId) y es editable durante 7 días.
 */
export class ResenaVerificada implements PropsResena {
  id: string;
  citaId: string;
  pacienteId: string;
  medicoId: string;
  autorUsuarioId: string;
  puntualidad: number;
  trato: number;
  claridad: number;
  instalaciones: number;
  comentario?: string;
  publicadaEn: Date;
  editadaEn?: Date;

  constructor(props: PropsResena) {
    Object.assign(this, props);
  }

  static publicar(
    datos: Omit<PropsResena, 'id' | 'publicadaEn' | 'editadaEn'>,
    ahora: Date,
  ): ResenaVerificada {
    ResenaVerificada.validar(datos);
    return new ResenaVerificada({ ...datos, id: generarId(), comentario: datos.comentario?.trim() || undefined, publicadaEn: ahora });
  }

  get promedio(): number {
    return (this.puntualidad + this.trato + this.claridad + this.instalaciones) / 4;
  }

  esEditable(ahora: Date): boolean {
    return ahora <= sumarDias(this.publicadaEn, DIAS_EDICION_RESENA);
  }

  editar(datos: Calificaciones & { comentario?: string }, ahora: Date): void {
    asegurar(this.esEditable(ahora), `La reseña solo puede editarse durante ${DIAS_EDICION_RESENA} días`);
    ResenaVerificada.validar(datos);
    Object.assign(this, { ...datos, comentario: datos.comentario?.trim() || undefined, editadaEn: ahora });
  }

  private static validar(c: Calificaciones & { comentario?: string }): void {
    for (const [criterio, valor] of Object.entries({
      puntualidad: c.puntualidad,
      trato: c.trato,
      claridad: c.claridad,
      instalaciones: c.instalaciones,
    })) {
      asegurar(Number.isInteger(valor) && valor >= 1 && valor <= 5, `La calificación de ${criterio} debe ser un entero de 1 a 5`);
    }
    asegurar(!c.comentario || c.comentario.length <= 1000, 'El comentario no puede superar 1000 caracteres');
  }
}

export interface EstadisticasMedico {
  total: number;
  promedio: number;
  puntualidad: number;
  trato: number;
  claridad: number;
  instalaciones: number;
}

export abstract class ResenaRepository {
  abstract guardar(resena: ResenaVerificada): Promise<void>;
  abstract buscarPorId(id: string): Promise<ResenaVerificada | null>;
  abstract buscarPorCita(citaId: string): Promise<ResenaVerificada | null>;
  abstract listarPorMedico(medicoId: string, limite: number): Promise<ResenaVerificada[]>;
  abstract estadisticas(medicoId: string): Promise<EstadisticasMedico>;
}
