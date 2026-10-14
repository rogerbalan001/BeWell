/**
 * Puerto del almacenamiento de objetos (datos no estructurados: PDF e
 * imágenes). El MVP usa un adapter de disco local cifrado; en sprints
 * posteriores se conecta un bucket S3 sin modificar los módulos.
 */
export interface ArchivoGuardado {
  ruta: string;
  tipoMime: string;
  tamanoBytes: number;
  nombreOriginal: string;
}

export interface ArchivoLeido {
  contenido: Buffer;
  tipoMime: string;
  nombreOriginal: string;
}

export abstract class AlmacenamientoArchivos {
  abstract guardar(carpeta: string, contenido: Buffer, tipoMime: string, nombreOriginal: string): Promise<ArchivoGuardado>;
  abstract leer(ruta: string): Promise<ArchivoLeido>;
  /** URL de lectura temporal firmada (equivalente a una URL prefirmada de S3). */
  abstract generarUrlLectura(ruta: string, segundosVigencia?: number): string;
  /** Valida un token de URL firmada y devuelve la ruta interna. */
  abstract resolverTokenLectura(token: string): string;
}

export const TIPOS_ARCHIVO_PERMITIDOS = ['application/pdf', 'image/jpeg', 'image/png'];
export const TAMANO_MAXIMO_ARCHIVO = 10 * 1024 * 1024; // 10 MB (criterio de aceptación HU exámenes)
