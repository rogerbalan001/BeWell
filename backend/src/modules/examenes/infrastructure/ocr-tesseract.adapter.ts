import { Injectable, Logger } from '@nestjs/common';
import { createWorker } from 'tesseract.js';
import pdfParse from 'pdf-parse/lib/pdf-parse.js';
import { ServicioOcr } from '../application/servicio-ocr';
import { AnalitoExtraido, extraerAnalitos } from '../domain/extractor-analitos';

/** Tiempo máximo para leer una imagen; si se pasa, el examen queda como adjunto. */
const LIMITE_OCR_MS = 45_000;
/** Un PDF con menos texto que esto es casi seguro un escaneo (solo imágenes). */
const MINIMO_TEXTO_PDF = 20;

/**
 * Adaptador de OCR real (HU: subir fotos o PDF y extraer los valores).
 *
 * - PDF digital: se lee el texto incrustado con pdf-parse (rápido y exacto).
 * - JPG/PNG: se reconoce el texto con Tesseract (modelo en español).
 *
 * Con el texto en mano, `extraerAnalitos` busca los valores del catálogo. Si no
 * encuentra ninguno devuelve `null` y el servicio guarda el examen como archivo
 * adjunto (criterio de aceptación 3). Un PDF escaneado sin texto también queda
 * como adjunto: rasterizar PDF queda para cuando haya una cola de trabajos.
 */
@Injectable()
export class OcrTesseractAdapter extends ServicioOcr {
  private readonly logger = new Logger(OcrTesseractAdapter.name);

  async extraer(archivo: { contenido: Buffer; tipoMime: string; nombre: string }): Promise<AnalitoExtraido[] | null> {
    const { texto, confianza } =
      archivo.tipoMime === 'application/pdf' ? await this.textoDePdf(archivo.contenido) : await this.textoDeImagen(archivo.contenido);
    if (!texto.trim()) return null;
    const resultados = extraerAnalitos(texto, confianza);
    this.logger.log(`OCR de "${archivo.nombre}": ${resultados.length} valores reconocidos`);
    return resultados.length ? resultados : null;
  }

  private async textoDePdf(contenido: Buffer): Promise<{ texto: string; confianza: number }> {
    const { text } = await pdfParse(contenido);
    // Texto incrustado: no hay incertidumbre de reconocimiento.
    return { texto: text.trim().length >= MINIMO_TEXTO_PDF ? text : '', confianza: 1 };
  }

  private async textoDeImagen(contenido: Buffer): Promise<{ texto: string; confianza: number }> {
    const worker = await createWorker('spa');
    let temporizador: NodeJS.Timeout | undefined;
    try {
      const limite = new Promise<never>((_, rechazar) => {
        temporizador = setTimeout(() => rechazar(new Error('El reconocimiento de texto tardó demasiado')), LIMITE_OCR_MS);
      });
      const { data } = await Promise.race([worker.recognize(contenido), limite]);
      // Tesseract reporta la confianza de 0 a 100.
      return { texto: data.text ?? '', confianza: (data.confidence ?? 0) / 100 };
    } finally {
      if (temporizador) clearTimeout(temporizador);
      await worker.terminate();
    }
  }
}
