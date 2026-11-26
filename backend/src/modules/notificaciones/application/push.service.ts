import { Injectable, Logger } from '@nestjs/common';
import { NuevaNotificacion } from '../../../shared/application/notificador';
import { Reloj } from '../../../shared/domain/reloj';
import { PushRepository, rutaDeNotificacion } from '../domain/push';
import { ClavesVapid, enviarPush, generarClavesVapid, SuscripcionPush } from '../infrastructure/web-push';

const CONTACTO = 'mailto:soporte@bewell.app';

/**
 * «Control» Notificaciones push (HU Sprint 4): cada aviso de la bandeja, incluidos los
 * recordatorios, también llega al teléfono del paciente que autorizó las notificaciones.
 */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  private claves?: Promise<ClavesVapid>;

  constructor(
    private readonly repositorio: PushRepository,
    private readonly reloj: Reloj,
  ) {}

  /** Claves VAPID: de las variables de entorno, o generadas una vez y guardadas (cifradas) en la base. */
  private obtenerClaves(): Promise<ClavesVapid> {
    this.claves ??= (async () => {
      const { VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY } = process.env;
      if (VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) return { publica: VAPID_PUBLIC_KEY, privada: VAPID_PRIVATE_KEY };
      const guardadas = await this.repositorio.obtenerClaves();
      if (guardadas) return guardadas;
      const nuevas = generarClavesVapid();
      await this.repositorio.guardarClaves(nuevas);
      return nuevas;
    })().catch((e) => {
      this.claves = undefined;
      throw e;
    });
    return this.claves;
  }

  async clavePublica(): Promise<string> {
    return (await this.obtenerClaves()).publica;
  }

  async suscribir(usuarioId: string, s: SuscripcionPush): Promise<void> {
    await this.repositorio.guardarSuscripcion(usuarioId, s, this.reloj.ahora());
  }

  async darDeBaja(endpoint: string): Promise<void> {
    await this.repositorio.eliminarSuscripcion(endpoint);
  }

  /** Envía la notificación a todos los dispositivos del usuario. Devuelve cuántos la aceptaron. */
  async enviar(n: NuevaNotificacion): Promise<number> {
    const suscripciones = await this.repositorio.suscripcionesDe(n.usuarioId);
    if (!suscripciones.length) return 0;
    const claves = await this.obtenerClaves();
    const contenido = { titulo: n.titulo, mensaje: n.mensaje, ruta: rutaDeNotificacion(n.tipo, n.datos) };
    let aceptadas = 0;
    for (const s of suscripciones) {
      try {
        const estado = await enviarPush(s, contenido, claves, CONTACTO);
        if (estado === 404 || estado === 410) await this.repositorio.eliminarSuscripcion(s.endpoint);
        else if (estado >= 200 && estado < 300) aceptadas++;
        else this.logger.warn(`El servicio push respondió ${estado}`);
      } catch (e) {
        this.logger.warn(`No se pudo enviar la notificación push: ${(e as Error).message}`);
      }
    }
    return aceptadas;
  }
}
