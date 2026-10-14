import { BadRequestException } from '@nestjs/common';
import { TAMANO_MAXIMO_ARCHIVO, TIPOS_ARCHIVO_PERMITIDOS } from '../../application/almacenamiento-archivos';

/** Archivo recibido por multipart (subconjunto de Express.Multer.File). */
export interface ArchivoSubido {
  buffer: Buffer;
  mimetype: string;
  originalname: string;
  size: number;
}

/** Valida tipo (JPG, PNG, PDF) y tamaño (≤ 10 MB) de un archivo subido. */
const MIME_POR_EXTENSION: Record<string, string> = { pdf: 'application/pdf', jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png' };

export function validarArchivo(archivo: ArchivoSubido | undefined): ArchivoSubido {
  if (!archivo) throw new BadRequestException('Debes adjuntar un archivo en el campo "archivo"');
  if (!TIPOS_ARCHIVO_PERMITIDOS.includes(archivo.mimetype)) {
    // Algunos clientes envían application/octet-stream: se infiere el tipo por la extensión.
    const extension = archivo.originalname.split('.').pop()?.toLowerCase() ?? '';
    if (MIME_POR_EXTENSION[extension]) archivo = { ...archivo, mimetype: MIME_POR_EXTENSION[extension] };
  }
  if (!TIPOS_ARCHIVO_PERMITIDOS.includes(archivo.mimetype)) {
    throw new BadRequestException('Formato no permitido: solo JPG, PNG o PDF');
  }
  if (archivo.size > TAMANO_MAXIMO_ARCHIVO) {
    throw new BadRequestException('El archivo supera el máximo de 10 MB');
  }
  return archivo;
}
