const DIAS = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
const dos = (n: number): string => n.toString().padStart(2, '0');

/** Formatea una fecha en la hora local indicada (desfase en minutos), p. ej. "jue 24/10 10:30". */
export function formatearFechaLocal(fecha: Date, desfaseMin: number): string {
  const l = new Date(fecha.getTime() + desfaseMin * 60_000);
  return `${DIAS[l.getUTCDay()]} ${dos(l.getUTCDate())}/${dos(l.getUTCMonth() + 1)} ${dos(l.getUTCHours())}:${dos(l.getUTCMinutes())}`;
}
