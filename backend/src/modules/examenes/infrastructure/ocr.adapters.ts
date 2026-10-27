import { Injectable } from '@nestjs/common';
import { ResultadoAnalito } from '../domain/examen-medico';
import { ServicioOcr } from '../application/servicio-ocr';

type Extraido = Omit<ResultadoAnalito, 'validadoPorMedico'>;

/** Sin proveedor de OCR: todos los exámenes quedan como adjuntos. */
@Injectable()
export class OcrNoDisponibleAdapter extends ServicioOcr {
  async extraer(): Promise<Extraido[] | null> {
    return null;
  }
}

const PLANTILLAS: { clave: RegExp; resultados: Extraido[] }[] = [
  {
    clave: /lip[ií]d/i,
    resultados: [
      { analito: 'Colesterol total', valor: '192', unidad: 'mg/dL', rangoReferencia: '< 200', confianzaOcr: 0.93 },
      { analito: 'Triglicéridos', valor: '140', unidad: 'mg/dL', rangoReferencia: '< 150', confianzaOcr: 0.9 },
      { analito: 'HDL', valor: '48', unidad: 'mg/dL', rangoReferencia: '> 40', confianzaOcr: 0.88 },
      { analito: 'LDL', valor: '116', unidad: 'mg/dL', rangoReferencia: '< 130', confianzaOcr: 0.81 },
    ],
  },
  {
    clave: /glic|gluc|hba1c/i,
    resultados: [{ analito: 'Glucosa en ayunas', valor: '88', unidad: 'mg/dL', rangoReferencia: '70 – 100', confianzaOcr: 0.95 }],
  },
  {
    clave: /hemat|hemograma/i,
    resultados: [
      { analito: 'Hemoglobina', valor: '14.2', unidad: 'g/dL', rangoReferencia: '13.5 – 17.5', confianzaOcr: 0.94 },
      { analito: 'Hematocrito', valor: '42', unidad: '%', rangoReferencia: '41 – 53', confianzaOcr: 0.9 },
      { analito: 'Leucocitos', valor: '6800', unidad: '/mm³', rangoReferencia: '4500 – 11000', confianzaOcr: 0.86 },
      { analito: 'Plaquetas', valor: '250000', unidad: '/mm³', rangoReferencia: '150000 – 450000', confianzaOcr: 0.78 },
    ],
  },
];

/**
 * OCR SIMULADO para la demostración del MVP: devuelve una plantilla de
 * analitos según el nombre del examen, con su nivel de confianza, para
 * ejercitar el flujo "extraer → revisar/corregir → confirmar". Los archivos
 * cuyo nombre contiene "ilegible" simulan un documento no reconocido.
 * Desde el Sprint 2 el OCR real es OcrTesseractAdapter (OCR_PROVIDER=tesseract);
 * este adaptador queda para demos sin conexión.
 */
@Injectable()
export class OcrSimuladoAdapter extends ServicioOcr {
  async extraer(archivo: { nombre: string }, pistas: string[]): Promise<Extraido[] | null> {
    if (/ilegible/i.test(archivo.nombre)) return null;
    const texto = [...pistas, archivo.nombre].join(' ');
    const encontrados = PLANTILLAS.filter((p) => p.clave.test(texto)).flatMap((p) => p.resultados);
    return encontrados.length ? encontrados.map((r) => ({ ...r })) : null;
  }
}
