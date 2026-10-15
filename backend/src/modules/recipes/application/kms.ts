/**
 * «Boundary» KmsAdapter (puerto). Custodia las llaves de firma: la llave
 * privada nunca sale del KMS (decisión D10).
 */
export abstract class Kms {
  abstract crearLlaveFirma(): Promise<string>;
  abstract firmar(llaveId: string, contenido: Buffer): Promise<string>;
  abstract obtenerLlavePublica(llaveId: string): Promise<string>;
}
