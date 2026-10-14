/** Línea de un documento PDF de texto. */
export interface LineaPdf {
  texto: string;
  tamano?: number;
  negrita?: boolean;
  color?: 'normal' | 'tenue' | 'primario';
  /** Espacio extra antes de la línea (puntos). */
  espacioAntes?: number;
}

/** Puerto para generar documentos PDF (exportación del expediente). */
export abstract class GeneradorPdf {
  abstract generar(titulo: string, lineas: LineaPdf[]): Buffer;
}
