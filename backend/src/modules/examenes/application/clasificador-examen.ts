import { ClasificacionExamen } from '../domain/clasificacion-examen';

/** Lo que el clasificador sabe del examen además del archivo. */
export interface PistasClasificacion {
  /** Analitos que el OCR ya reconoció (glucosa, colesterol…), si los hay. */
  analitos: string[];
  /** Nombre que escribió el paciente, si escribió alguno. */
  tituloPaciente?: string;
}

/** Sugerencia de la IA (siempre con origen IA y una confianza entre 0 y 1). */
export type SugerenciaClasificacion = Omit<ClasificacionExamen, 'origen'> & { confianza: number };

/**
 * «Boundary» ClasificadorExamen (puerto). Sugiere la categoría y el tipo de un
 * examen a partir del archivo. Devuelve null si no lo reconoce; el servicio
 * nunca bloquea la carga si el clasificador falla.
 */
export abstract class ClasificadorExamen {
  abstract clasificar(
    archivo: { contenido: Buffer; tipoMime: string; nombre: string },
    pistas: PistasClasificacion,
  ): Promise<SugerenciaClasificacion | null>;
}
