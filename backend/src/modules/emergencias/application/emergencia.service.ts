import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Notificador } from '../../../shared/application/notificador';
import { RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario, tieneRol } from '../../../shared/domain/roles';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { DatosFicha, FichaEmergencia, FichaEmergenciaRepository, VistaFicha } from '../domain/ficha-emergencia';
import { FichaCacheada, FichaEmergenciaCache } from './ficha-emergencia.cache';

const TTL_CACHE_SEGUNDOS = 600;

export interface FichaPorToken {
  paciente: FichaCacheada['paciente'];
  ficha: VistaFicha;
}

/**
 * «Control» EmergenciaService. HU: el personal de emergencias escanea el QR y
 * ve la ficha sin iniciar sesión. Ruta crítica: caché → índice único → filtrado.
 */
@Injectable()
export class EmergenciaService {
  private readonly logger = new Logger(EmergenciaService.name);

  constructor(
    private readonly fichas: FichaEmergenciaRepository,
    private readonly cache: FichaEmergenciaCache,
    private readonly perfiles: PerfilesService,
    private readonly auditoria: RegistroAuditoria,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
    private readonly config: ConfigService,
  ) {}

  async obtenerFicha(actor: Actor, pacienteId: string): Promise<FichaEmergencia> {
    await this.perfiles.asegurarGestion(actor, pacienteId);
    return (await this.fichas.buscarPorPaciente(pacienteId)) ?? FichaEmergencia.vacia(pacienteId, this.reloj.ahora());
  }

  async actualizarFicha(actor: Actor, pacienteId: string, datos: DatosFicha): Promise<FichaEmergencia> {
    const ficha = await this.obtenerFicha(actor, pacienteId);
    ficha.actualizar(datos, this.reloj.ahora());
    await this.fichas.guardar(ficha);
    if (ficha.tokenQrHash) await this.cache.invalidar(ficha.tokenQrHash);
    return ficha;
  }

  /** Regenerar el QR invalida de inmediato el token anterior y su entrada en caché. */
  async regenerarQr(actor: Actor, pacienteId: string): Promise<{ token: string; url: string; generadoEn: Date }> {
    const ficha = await this.obtenerFicha(actor, pacienteId);
    const { token, hashAnterior } = ficha.regenerarToken(this.reloj.ahora());
    await this.fichas.guardar(ficha);
    if (hashAnterior) await this.cache.invalidar(hashAnterior);
    return { token, url: this.urlPublica(token), generadoEn: ficha.qrGeneradoEn! };
  }

  async obtenerFichaPorToken(token: string, solicitante: Actor | undefined, ip?: string): Promise<FichaPorToken> {
    const hash = FichaEmergencia.hashToken(token);
    let cacheada = await this.cache.obtener(hash);
    if (!cacheada) {
      const ficha = await this.fichas.buscarPorTokenHash(hash);
      if (!ficha) throw new NoEncontradoError('Ficha de emergencia');
      const paciente = await this.perfiles.obtener(ficha.pacienteId);
      cacheada = {
        ficha: { ...ficha },
        paciente: { nombreCompleto: paciente.nombreCompleto, edad: paciente.edad(this.reloj.ahora()), sexo: paciente.sexo },
        titularUsuarioId: paciente.titularUsuarioId,
      };
      await this.cache.guardar(hash, cacheada, TTL_CACHE_SEGUNDOS);
    }
    const ficha = new FichaEmergencia({ ...cacheada.ficha, actualizadoEn: new Date(cacheada.ficha.actualizadoEn) });
    const ampliada = tieneRol(solicitante, RolUsuario.PERSONAL_EMERGENCIA);
    // Auditoría y aviso al titular fuera de la ruta crítica de latencia.
    void this.registrarAcceso(ficha.pacienteId, cacheada.titularUsuarioId, solicitante, ampliada, ip);
    return { paciente: cacheada.paciente, ficha: ficha.vista(ampliada) };
  }

  urlPublica(token: string): string {
    return `${this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:8080/#'}/e/${token}`;
  }

  private async registrarAcceso(pacienteId: string, titularId: string, actor: Actor | undefined, ampliada: boolean, ip?: string): Promise<void> {
    try {
      await this.auditoria.registrar({
        actorId: actor?.id,
        rolActor: ampliada ? RolUsuario.PERSONAL_EMERGENCIA : 'ANONIMO',
        accion: 'LEER_FICHA_EMERGENCIA',
        recurso: 'ficha_emergencia',
        pacienteId,
        accesoEmergencia: true,
        ip,
      });
      await this.notificador.notificar({
        usuarioId: titularId,
        tipo: 'EMERGENCIA',
        titulo: 'Se consultó una ficha de emergencia',
        mensaje: `Alguien escaneó el código QR de emergencia (${ampliada ? 'personal de emergencia verificado' : 'acceso público'}).`,
        datos: { pacienteId },
      });
    } catch (e) {
      this.logger.error(`No se pudo registrar el acceso a la ficha: ${(e as Error).message}`);
    }
  }
}
