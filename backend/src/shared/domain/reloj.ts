/**
 * Puerto de tiempo. Inyectarlo en lugar de usar `new Date()` directamente
 * permite probar reglas que dependen de la fecha (vencimientos, 24 h, 48 h…).
 */
export abstract class Reloj {
  abstract ahora(): Date;
}

export class RelojSistema extends Reloj {
  ahora(): Date {
    return new Date();
  }
}

export const HORA_MS = 60 * 60 * 1000;
export const DIA_MS = 24 * HORA_MS;
export const sumarHoras = (fecha: Date, horas: number): Date => new Date(fecha.getTime() + horas * HORA_MS);
export const sumarDias = (fecha: Date, dias: number): Date => new Date(fecha.getTime() + dias * DIA_MS);
export const horasEntre = (desde: Date, hasta: Date): number => (hasta.getTime() - desde.getTime()) / HORA_MS;
