/** Tipos de recordatorio que el paciente puede activar o desactivar (criterio 3 de la HU). */
export enum TipoRecordatorio {
  CITAS = 'CITAS',
  MEDICAMENTOS = 'MEDICAMENTOS',
  EXAMENES = 'EXAMENES',
}

export type CambiosPreferencias = Partial<Record<'citas' | 'medicamentos' | 'examenes', boolean>>;

/**
 * «Entity» PreferenciasRecordatorio: una por usuario titular. Aplica a todos
 * los perfiles que gestiona (sus hijos o padres incluidos). Por defecto todo
 * está activado: recordar es la razón de ser de la HU.
 */
export class PreferenciasRecordatorio {
  constructor(
    readonly usuarioId: string,
    public citas: boolean,
    public medicamentos: boolean,
    public examenes: boolean,
    public actualizadoEn: Date,
  ) {}

  static porDefecto(usuarioId: string, ahora: Date): PreferenciasRecordatorio {
    return new PreferenciasRecordatorio(usuarioId, true, true, true, ahora);
  }

  actualizar(cambios: CambiosPreferencias, ahora: Date): void {
    if (typeof cambios.citas === 'boolean') this.citas = cambios.citas;
    if (typeof cambios.medicamentos === 'boolean') this.medicamentos = cambios.medicamentos;
    if (typeof cambios.examenes === 'boolean') this.examenes = cambios.examenes;
    this.actualizadoEn = ahora;
  }

  permite(tipo: TipoRecordatorio): boolean {
    switch (tipo) {
      case TipoRecordatorio.CITAS:
        return this.citas;
      case TipoRecordatorio.MEDICAMENTOS:
        return this.medicamentos;
      case TipoRecordatorio.EXAMENES:
        return this.examenes;
    }
  }
}
