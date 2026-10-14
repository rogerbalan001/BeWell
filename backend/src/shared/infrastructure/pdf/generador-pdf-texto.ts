import { GeneradorPdf, LineaPdf } from '../../application/generador-pdf';

const ANCHO = 595.28; // A4
const ALTO = 841.89;
const MARGEN = 50;

const COLORES: Record<string, string> = { normal: '0.04 0.15 0.25', tenue: '0.39 0.45 0.55', primario: '0.10 0.42 0.94' };

/** Reemplaza caracteres fuera de WinAnsi por equivalentes y escapa los especiales de PDF. */
function codificar(texto: string): string {
  const normalizado = texto
    .replace(/[“”«»]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[–—]/g, '-')
    .replace(/[•·]/g, '-')
    .replace(/→/g, '->')
    .replace(/…/g, '...')
    .replace(/[^\x20-\x7E\xA0-\xFF]/g, '');
  return normalizado.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

/** Corta una línea según un ancho aproximado de Helvetica (0,5 em por carácter). */
function envolver(texto: string, tamano: number): string[] {
  const maximo = Math.floor((ANCHO - 2 * MARGEN) / (tamano * 0.5));
  const resultado: string[] = [];
  for (const parrafo of texto.split('\n')) {
    let actual = '';
    for (const palabra of parrafo.split(/\s+/)) {
      if ((actual + ' ' + palabra).trim().length > maximo) {
        if (actual) resultado.push(actual);
        actual = palabra;
      } else {
        actual = (actual + ' ' + palabra).trim();
      }
    }
    resultado.push(actual);
  }
  return resultado;
}

/**
 * Generador de PDF de solo texto sin dependencias externas (Helvetica,
 * WinAnsiEncoding, paginación A4). Suficiente para exportar el expediente en
 * el MVP; se puede sustituir por una plantilla HTML→PDF más adelante.
 */
export class GeneradorPdfTexto extends GeneradorPdf {
  generar(titulo: string, lineas: LineaPdf[]): Buffer {
    const paginas: string[] = [];
    let flujo = '';
    let y = ALTO - MARGEN;
    const nuevaPagina = () => {
      if (flujo) paginas.push(flujo);
      flujo = '';
      y = ALTO - MARGEN;
    };
    for (const l of lineas) {
      const tamano = l.tamano ?? 10;
      const alto = tamano * 1.45;
      y -= l.espacioAntes ?? 0;
      for (const fragmento of envolver(l.texto, tamano)) {
        if (y - alto < MARGEN + 20) nuevaPagina();
        y -= alto;
        flujo += `BT /${l.negrita ? 'F2' : 'F1'} ${tamano} Tf ${COLORES[l.color ?? 'normal']} rg ${MARGEN} ${y.toFixed(2)} Td (${codificar(fragmento)}) Tj ET\n`;
      }
    }
    nuevaPagina();

    const total = paginas.length;
    const objetos: string[] = [];
    // 1: catálogo, 2: páginas, 3: Helvetica, 4: Helvetica-Bold, luego (página, contenido) por cada página.
    const idsPaginas = paginas.map((_, i) => 5 + i * 2);
    objetos[1] = '<< /Type /Catalog /Pages 2 0 R >>';
    objetos[2] = `<< /Type /Pages /Kids [${idsPaginas.map((id) => `${id} 0 R`).join(' ')}] /Count ${total} >>`;
    objetos[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
    objetos[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';
    paginas.forEach((contenido, i) => {
      const pie = `BT /F1 8 Tf ${COLORES.tenue} rg ${MARGEN} 30 Td (${codificar(`${titulo} - pagina ${i + 1} de ${total}`)}) Tj ET\n`;
      const cuerpo = Buffer.from(contenido + pie, 'latin1');
      objetos[idsPaginas[i]] =
        `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${ANCHO} ${ALTO}] ` +
        `/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents ${idsPaginas[i] + 1} 0 R >>`;
      objetos[idsPaginas[i] + 1] = `<< /Length ${cuerpo.length} >>\nstream\n${contenido + pie}endstream`;
    });

    let salida = '%PDF-1.4\n%\xE2\xE3\xCF\xD3\n';
    const desplazamientos: number[] = [];
    for (let id = 1; id < objetos.length; id++) {
      desplazamientos[id] = Buffer.byteLength(salida, 'latin1');
      salida += `${id} 0 obj\n${objetos[id]}\nendobj\n`;
    }
    const inicioXref = Buffer.byteLength(salida, 'latin1');
    salida += `xref\n0 ${objetos.length}\n0000000000 65535 f \n`;
    for (let id = 1; id < objetos.length; id++) salida += `${String(desplazamientos[id]).padStart(10, '0')} 00000 n \n`;
    salida += `trailer\n<< /Size ${objetos.length} /Root 1 0 R /Info << /Title (${codificar(titulo)}) /Producer (Bewell) >> >>\nstartxref\n${inicioXref}\n%%EOF\n`;
    return Buffer.from(salida, 'latin1');
  }
}
