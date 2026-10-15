import { Centavos, porcentajeDe } from '../../../shared/domain/dinero';
import { ReglaNegocioError } from '../../../shared/domain/errores';

export type TipoPolitica = 'FLEXIBLE' | 'MODERADA' | 'ESTRICTA';

interface DefinicionPolitica {
  horasMinimasAviso: number;
  /** Fracción (0–1) del monto que se retiene si se cancela tarde. */
  porcentajePenalizacion: number;
}

export const CATALOGO_POLITICAS: Record<TipoPolitica, DefinicionPolitica> = {
  FLEXIBLE: { horasMinimasAviso: 2, porcentajePenalizacion: 0.5 },
  MODERADA: { horasMinimasAviso: 24, porcentajePenalizacion: 0.5 },
  ESTRICTA: { horasMinimasAviso: 48, porcentajePenalizacion: 1 },
};

/**
 * «Entity» embebida PoliticaCancelacion (value object). Se embebe en Medico y
 * se COPIA en cada Cita al agendar (decisión D7): el reembolso se calcula con
 * la política aceptada aunque el médico la cambie después.
 */
export class PoliticaCancelacion {
  constructor(
    readonly tipo: TipoPolitica,
    readonly horasMinimasAviso: number,
    readonly porcentajePenalizacion: number,
  ) {}

  static desdeTipo(tipo: TipoPolitica): PoliticaCancelacion {
    const def = CATALOGO_POLITICAS[tipo];
    if (!def) throw new ReglaNegocioError(`Política de cancelación desconocida: ${tipo}`);
    return new PoliticaCancelacion(tipo, def.horasMinimasAviso, def.porcentajePenalizacion);
  }

  static porDefecto(): PoliticaCancelacion {
    return PoliticaCancelacion.desdeTipo('MODERADA');
  }

  /** Monto a reembolsar según la anticipación con que se cancela. */
  calcularReembolso(monto: Centavos, horasAntelacion: number): Centavos {
    if (horasAntelacion >= this.horasMinimasAviso) return monto;
    return monto - porcentajeDe(monto, this.porcentajePenalizacion);
  }

  get descripcion(): string {
    const retenido = Math.round(this.porcentajePenalizacion * 100);
    const tarde = retenido === 100 ? 'sin reembolso' : `reembolso del ${100 - retenido} %`;
    return `Reembolso total si cancelas con al menos ${this.horasMinimasAviso} h de anticipación; después, ${tarde}.`;
  }
}
