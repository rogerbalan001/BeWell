import { Injectable } from '@nestjs/common';
import { AlmacenamientoArchivos } from '../../../shared/application/almacenamiento-archivos';
import { Notificador } from '../../../shared/application/notificador';
import { NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { CredencialProfesional, EstadoVerificacion, TipoCredencial } from '../domain/credencial-profesional';
import { Medico } from '../domain/medico';
import { MedicoRepository } from '../domain/medico.repository';
import { MedicosService } from './medicos.service';

export interface ArchivoCredencial {
  contenido: Buffer;
  tipoMime: string;
  nombreOriginal: string;
}

/**
 * «Control» HU: validar título, colegiatura y cédula de cada médico.
 * Actualiza el estado de cada credencial y recalcula el estado global.
 */
@Injectable()
export class VerificacionProfesionalService {
  constructor(
    private readonly medicos: MedicoRepository,
    private readonly medicosService: MedicosService,
    private readonly almacenamiento: AlmacenamientoArchivos,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
  ) {}

  async registrarCredencial(
    actor: Actor,
    tipo: TipoCredencial,
    numero: string,
    archivo: ArchivoCredencial,
  ): Promise<CredencialProfesional> {
    const medico = await this.medicosService.delActor(actor);
    const guardado = await this.almacenamiento.guardar('credenciales', archivo.contenido, archivo.tipoMime, archivo.nombreOriginal);
    const credencial = medico.registrarCredencial(tipo, numero, guardado.ruta, this.reloj.ahora());
    await this.medicos.guardar(medico);
    return credencial;
  }

  listarPendientes(): Promise<Medico[]> {
    return this.medicos.buscarConCredencialesPendientes();
  }

  async aprobarCredencial(adminId: string, medicoId: string, credencialId: string): Promise<Medico> {
    const medico = await this.medicosService.obtener(medicoId);
    const estadoAnterior = medico.estadoVerificacion;
    medico.aprobarCredencial(credencialId, adminId, this.reloj.ahora());
    await this.medicos.guardar(medico);
    if (estadoAnterior !== EstadoVerificacion.APROBADO && medico.estaVerificado()) {
      await this.notificador.notificar({
        usuarioId: medico.usuarioId,
        tipo: 'VERIFICACION',
        titulo: '¡Perfil verificado!',
        mensaje: 'Tus credenciales fueron aprobadas. Tu perfil ya es público y muestra la insignia "Médico verificado".',
      });
    }
    return medico;
  }

  async rechazarCredencial(adminId: string, medicoId: string, credencialId: string, motivo: string): Promise<Medico> {
    const medico = await this.medicosService.obtener(medicoId);
    medico.rechazarCredencial(credencialId, adminId, motivo, this.reloj.ahora());
    await this.medicos.guardar(medico);
    const credencial = medico.credenciales.find((c) => c.id === credencialId);
    await this.notificador.notificar({
      usuarioId: medico.usuarioId,
      tipo: 'VERIFICACION',
      titulo: 'Credencial rechazada',
      mensaje: `Tu ${credencial?.tipo.toLowerCase()} fue rechazado: ${motivo}. Vuelve a cargarlo para continuar.`,
    });
    return medico;
  }

  async urlArchivo(medicoId: string, credencialId: string): Promise<string> {
    const medico = await this.medicosService.obtener(medicoId);
    const credencial = medico.credenciales.find((c) => c.id === credencialId);
    if (!credencial) throw new NoEncontradoError('Credencial', credencialId);
    return this.almacenamiento.generarUrlLectura(credencial.archivoRef, 300);
  }
}
