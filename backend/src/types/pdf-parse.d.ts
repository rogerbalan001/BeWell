/**
 * Tipos mínimos de pdf-parse. Se importa `pdf-parse/lib/pdf-parse.js` en lugar
 * del paquete raíz porque el index.js del paquete ejecuta un archivo de prueba
 * cuando se carga sin `module.parent` (pasa al compilar con Nest).
 */
declare module 'pdf-parse/lib/pdf-parse.js' {
  interface ResultadoPdf {
    text: string;
    numpages: number;
  }
  function pdfParse(contenido: Buffer): Promise<ResultadoPdf>;
  export default pdfParse;
}
