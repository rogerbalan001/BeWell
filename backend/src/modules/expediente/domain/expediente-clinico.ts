import { generarId } from '../../../shared/domain/id';

/**
 * «Entity» ExpedienteClinico: documento pequeño, uno por paciente e
 * independiente del médico (HU: ser dueño de mi expediente). La línea de
 * tiempo vive en la colección de eventos clínicos (decisión D3).
 */
export class ExpedienteClinico {
  constructor(
    readonly id: string,
    readonly pacienteId: string,
    public antecedentes: string[],
    public actualizadoEn: Date,
  ) {}

  static abrir(pacienteId: string, ahora: Date): ExpedienteClinico {
    return new ExpedienteClinico(generarId(), pacienteId, [], ahora);
  }

  actualizarAntecedentes(antecedentes: string[], ahora: Date): void {
    this.antecedentes = antecedentes.map((a) => a.trim()).filter(Boolean);
    this.actualizadoEn = ahora;
  }
}
