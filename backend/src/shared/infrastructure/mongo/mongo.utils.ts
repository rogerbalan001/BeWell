import { Types } from 'mongoose';

/** Conversión entre los identificadores del dominio (string) y ObjectId. */
export const oid = (id: string): Types.ObjectId => new Types.ObjectId(id);
export const oidOpcional = (id?: string | null): Types.ObjectId | undefined => (id ? new Types.ObjectId(id) : undefined);
export const str = (valor: unknown): string => String(valor);
export const strOpcional = (valor: unknown): string | undefined => (valor == null ? undefined : String(valor));

/** Dinero: centavos en el dominio ↔ Decimal128 en MongoDB (decisión D8). */
export const aDecimal128 = (centavos: number): Types.Decimal128 => Types.Decimal128.fromString((centavos / 100).toFixed(2));
export const deDecimal128 = (valor: unknown): number => (valor == null ? 0 : Math.round(parseFloat(String(valor)) * 100));
