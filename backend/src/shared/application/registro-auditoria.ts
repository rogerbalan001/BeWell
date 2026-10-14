/** Puerto que usan los módulos clínicos para registrar accesos (módulo Auditoría). */
export interface EntradaAuditoria {
  actorId?: string;
  rolActor: string;
  accion: string;
  recurso: string;
  recursoId?: string;
  pacienteId?: string;
  accesoEmergencia?: boolean;
  ip?: string;
}

export abstract class RegistroAuditoria {
  abstract registrar(entrada: EntradaAuditoria): Promise<void>;
}
