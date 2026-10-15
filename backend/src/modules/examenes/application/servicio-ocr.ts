import { ResultadoAnalito } from '../domain/examen-medico';

/**
 * «Boundary» ServicioOcrAdapter (puerto). En la arquitectura objetivo lo
 * invoca un worker que consume una cola; en el MVP se invoca en línea y, si
 * falla o no reconoce el documento, el examen queda disponible como archivo.
 */
export abstract class ServicioOcr {
  abstract extraer(
    archivo: { contenido: Buffer; tipoMime: string; nombre: string },
    pistas: string[],
  ): Promise<Omit<ResultadoAnalito, 'validadoPorMedico'>[] | null>;
}
