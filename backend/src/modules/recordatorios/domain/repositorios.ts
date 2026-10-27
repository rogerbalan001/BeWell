import { PreferenciasRecordatorio } from './preferencias-recordatorio';

export abstract class PreferenciasRecordatorioRepository {
  abstract buscar(usuarioId: string): Promise<PreferenciasRecordatorio | null>;
  abstract guardar(preferencias: PreferenciasRecordatorio): Promise<void>;
}

/**
 * Registro de recordatorios ya enviados. Hace que el envío sea idempotente: el
 * worker puede revisar la misma ventana dos veces (reinicio, dos instancias)
 * sin mandar el mismo recordatorio dos veces.
 */
export abstract class RegistroEnviosRepository {
  /** Devuelve `true` si la clave es nueva (y la registra); `false` si ya se había enviado. */
  abstract registrarSiNuevo(clave: string, ahora: Date): Promise<boolean>;
}
