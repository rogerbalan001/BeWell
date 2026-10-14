/**
 * El dinero se maneja en el dominio como enteros de centavos para evitar
 * errores de coma flotante. En MongoDB se persiste como Decimal128 (decisión D8).
 */
export type Centavos = number;

export const aCentavos = (monto: number): Centavos => Math.round(monto * 100);
export const aMonto = (centavos: Centavos): number => centavos / 100;
export const formatearMonto = (centavos: Centavos): string => (centavos / 100).toFixed(2);

/** Aplica un porcentaje (0–1) y redondea al centavo. */
export const porcentajeDe = (centavos: Centavos, porcentaje: number): Centavos =>
  Math.round(centavos * porcentaje);
