import { asegurar } from '../../../shared/domain/errores';

/** «Entity» embebida BloqueHorario: franja semanal de atención del médico. */
export interface BloqueHorario {
  /** 0 = domingo … 6 = sábado. */
  diaSemana: number;
  /** "HH:mm" en la hora local del médico. */
  horaInicio: string;
  horaFin: string;
  duracionCitaMin: number;
}

export interface Franja {
  inicio: Date;
  fin: Date;
}

const HORA = /^([01]\d|2[0-3]):([0-5]\d)$/;
export const aMinutos = (hora: string): number => {
  const [h, m] = hora.split(':').map(Number);
  return h * 60 + m;
};

export function validarBloques(bloques: BloqueHorario[]): void {
  for (const b of bloques) {
    asegurar(Number.isInteger(b.diaSemana) && b.diaSemana >= 0 && b.diaSemana <= 6, 'diaSemana debe estar entre 0 y 6');
    asegurar(HORA.test(b.horaInicio) && HORA.test(b.horaFin), 'Las horas deben tener formato HH:mm');
    asegurar(aMinutos(b.horaInicio) < aMinutos(b.horaFin), 'La hora de inicio debe ser anterior a la de fin');
    asegurar(b.duracionCitaMin >= 15 && b.duracionCitaMin <= 240, 'La duración de cita debe estar entre 15 y 240 minutos');
  }
  for (let i = 0; i < bloques.length; i++) {
    for (let j = i + 1; j < bloques.length; j++) {
      const a = bloques[i];
      const b = bloques[j];
      const solapan =
        a.diaSemana === b.diaSemana &&
        aMinutos(a.horaInicio) < aMinutos(b.horaFin) &&
        aMinutos(b.horaInicio) < aMinutos(a.horaFin);
      asegurar(!solapan, `Hay bloques que se solapan el día ${a.diaSemana}`);
    }
  }
}
