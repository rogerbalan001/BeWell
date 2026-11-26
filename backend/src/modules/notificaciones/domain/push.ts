import { ClavesVapid, SuscripcionPush } from '../infrastructure/web-push';

/** «Repository» de suscripciones push por usuario y de las claves VAPID del servidor. */
export abstract class PushRepository {
  abstract guardarSuscripcion(usuarioId: string, s: SuscripcionPush, ahora: Date): Promise<void>;
  abstract eliminarSuscripcion(endpoint: string): Promise<void>;
  abstract suscripcionesDe(usuarioId: string): Promise<SuscripcionPush[]>;
  abstract obtenerClaves(): Promise<ClavesVapid | null>;
  abstract guardarClaves(claves: ClavesVapid): Promise<void>;
}

/** Pantalla de la app que abre la notificación (mismas reglas que la bandeja de notificaciones). */
export function rutaDeNotificacion(tipo: string, datos: Record<string, string> = {}): string {
  if (tipo === 'CHAT' && datos.citaId) return `/citas/${datos.citaId}/chat`;
  if (datos.citaId) return `/citas/${datos.citaId}`;
  if (tipo === 'RECORDATORIO' && datos.tipo === 'MEDICAMENTOS') return '/recipes';
  if (tipo === 'RECORDATORIO' && datos.tipo === 'EXAMENES') return '/examenes';
  if (tipo === 'RECORDATORIO') return '/recordatorios';
  if (tipo === 'REFERENCIA') return '/referencias';
  if (tipo === 'EXAMEN') return '/examenes';
  if (tipo === 'RECIPE') return '/recipes';
  if (tipo === 'VERIFICACION') return '/medico/credenciales';
  return '/notificaciones';
}
