import { randomBytes } from 'crypto';
import { asegurar, ReglaNegocioError } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { sumarDias } from '../../../shared/domain/reloj';

/** «Entity» embebida ItemRecipe. */
export interface ItemRecipe {
  medicamento: string;
  presentacion: string;
  dosis: string;
  frecuencia: string;
  duracionDias: number;
  indicaciones?: string;
}

export enum EstadoRecipe {
  VIGENTE = 'VIGENTE',
  ANULADO = 'ANULADO',
}

export const ALGORITMO_FIRMA = 'ECDSA_P256_SHA256';

export interface PropsRecipe {
  id: string;
  citaId: string;
  medicoId: string;
  pacienteId: string;
  items: ItemRecipe[];
  diagnostico?: string;
  codigoVerificacion: string;
  emitidoEn: Date;
  validoHasta: Date;
  hashContenido: string;
  firma: string;
  llaveFirmaId: string;
  algoritmo: string;
  estado: EstadoRecipe;
  motivoAnulacion?: string;
  anuladoEn?: Date;
}

const ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/**
 * «Entity» RecipeDigital. Su contenido canónico (RFC 8785) se firma con la
 * llave ECDSA P-256 del médico. Cualquier farmacia verifica emisor, estado e
 * integridad con el código de verificación o el QR.
 */
export class RecipeDigital implements PropsRecipe {
  id: string;
  citaId: string;
  medicoId: string;
  pacienteId: string;
  items: ItemRecipe[];
  diagnostico?: string;
  codigoVerificacion: string;
  emitidoEn: Date;
  validoHasta: Date;
  hashContenido: string;
  firma: string;
  llaveFirmaId: string;
  algoritmo: string;
  estado: EstadoRecipe;
  motivoAnulacion?: string;
  anuladoEn?: Date;

  constructor(props: PropsRecipe) {
    Object.assign(this, props);
  }

  /** Crea el récipe sin firma; la firma se agrega con `firmar()`. */
  static borrador(
    datos: { citaId: string; medicoId: string; pacienteId: string; items: ItemRecipe[]; diagnostico?: string; validoDias: number },
    ahora: Date,
  ): RecipeDigital {
    asegurar(datos.items.length > 0, 'El récipe debe incluir al menos un medicamento');
    for (const i of datos.items) {
      asegurar(i.medicamento?.trim() && i.dosis?.trim() && i.frecuencia?.trim(), 'Cada medicamento requiere nombre, dosis y frecuencia');
      asegurar(Number.isInteger(i.duracionDias) && i.duracionDias > 0, 'La duración del tratamiento debe ser un número de días');
    }
    asegurar(datos.validoDias >= 1 && datos.validoDias <= 180, 'La vigencia debe estar entre 1 y 180 días');
    return new RecipeDigital({
      id: generarId(),
      citaId: datos.citaId,
      medicoId: datos.medicoId,
      pacienteId: datos.pacienteId,
      items: datos.items.map((i) => ({ ...i, medicamento: i.medicamento.trim(), indicaciones: i.indicaciones?.trim() || undefined })),
      diagnostico: datos.diagnostico?.trim() || undefined,
      codigoVerificacion: RecipeDigital.generarCodigo(),
      emitidoEn: ahora,
      validoHasta: sumarDias(ahora, datos.validoDias),
      hashContenido: '',
      firma: '',
      llaveFirmaId: '',
      algoritmo: ALGORITMO_FIRMA,
      estado: EstadoRecipe.VIGENTE,
    });
  }

  static generarCodigo(): string {
    const bytes = randomBytes(10);
    const c = Array.from(bytes, (b) => ALFABETO[b % ALFABETO.length]).join('');
    return `RX-${c.slice(0, 5)}-${c.slice(5)}`;
  }

  /** Contenido que se firma: todo lo clínicamente relevante e inmutable. */
  contenidoFirmable(): Record<string, unknown> {
    return {
      v: 1,
      codigo: this.codigoVerificacion,
      citaId: this.citaId,
      medicoId: this.medicoId,
      pacienteId: this.pacienteId,
      diagnostico: this.diagnostico ?? null,
      items: this.items.map((i) => ({ ...i, indicaciones: i.indicaciones ?? null })),
      emitidoEn: this.emitidoEn.toISOString(),
      validoHasta: this.validoHasta.toISOString(),
    };
  }

  firmar(hashContenido: string, firma: string, llaveFirmaId: string): void {
    this.hashContenido = hashContenido;
    this.firma = firma;
    this.llaveFirmaId = llaveFirmaId;
  }

  estaVigente(ahora: Date): boolean {
    return this.estado === EstadoRecipe.VIGENTE && ahora <= this.validoHasta;
  }

  anular(motivo: string, ahora: Date): void {
    if (this.estado === EstadoRecipe.ANULADO) throw new ReglaNegocioError('El récipe ya estaba anulado');
    asegurar(motivo?.trim(), 'Indica el motivo de la anulación');
    this.estado = EstadoRecipe.ANULADO;
    this.motivoAnulacion = motivo.trim();
    this.anuladoEn = ahora;
  }
}

export abstract class RecipeRepository {
  abstract guardar(recipe: RecipeDigital): Promise<void>;
  abstract buscarPorId(id: string): Promise<RecipeDigital | null>;
  abstract buscarPorCodigo(codigo: string): Promise<RecipeDigital | null>;
  abstract listarPorPaciente(pacienteId: string): Promise<RecipeDigital[]>;
  abstract listarPorMedico(medicoId: string): Promise<RecipeDigital[]>;
}
