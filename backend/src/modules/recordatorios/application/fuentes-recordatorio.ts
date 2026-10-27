/** Datos mínimos de una cita confirmada para recordarla. */
export interface CitaParaRecordar {
  id: string;
  pacienteId: string;
  medicoId: string;
  inicio: Date;
  modalidad: string;
}

/** Récipe vigente con sus medicamentos (ya descifrados). */
export interface RecipeParaRecordar {
  id: string;
  pacienteId: string;
  emitidoEn: Date;
  items: { medicamento: string; presentacion?: string; dosis: string; frecuencia: string; duracionDias: number }[];
}

/** Orden de exámenes que sigue pendiente de resultados. */
export interface OrdenParaRecordar {
  id: string;
  pacienteId: string;
  examenes: string[];
  creadaEn: Date;
}

/**
 * Puerto de lectura sobre citas, récipes y órdenes de exámenes. Los
 * recordatorios solo LEEN esos datos; los módulos dueños siguen siendo los
 * únicos que los modifican. `pacienteIds` limita la búsqueda (para la vista
 * "próximos recordatorios" de un usuario); sin él busca en todos (worker).
 */
export abstract class FuentesRecordatorio {
  abstract citasConfirmadasEntre(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<CitaParaRecordar[]>;
  abstract recipesVigentes(emitidosDesde: Date, pacienteIds?: string[]): Promise<RecipeParaRecordar[]>;
  abstract ordenesPendientes(creadasDesde: Date, pacienteIds?: string[]): Promise<OrdenParaRecordar[]>;
}
