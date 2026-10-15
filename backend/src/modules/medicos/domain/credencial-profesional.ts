export enum EstadoVerificacion {
  PENDIENTE = 'PENDIENTE',
  APROBADO = 'APROBADO',
  RECHAZADO = 'RECHAZADO',
}

export type TipoCredencial = 'TITULO' | 'COLEGIATURA' | 'CEDULA';
export const TIPOS_CREDENCIAL: TipoCredencial[] = ['TITULO', 'COLEGIATURA', 'CEDULA'];

/**
 * «Entity» embebida CredencialProfesional. Cada credencial tiene su propio
 * estado: el administrador puede aprobar el título y rechazar la colegiatura
 * de forma independiente.
 */
export interface CredencialProfesional {
  id: string;
  tipo: TipoCredencial;
  numero: string;
  archivoRef: string;
  estado: EstadoVerificacion;
  enviadaEn: Date;
  revisadoPorId?: string;
  fechaRevision?: Date;
  observaciones?: string;
}
