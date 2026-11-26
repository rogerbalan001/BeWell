import { Injectable } from '@nestjs/common';
import { AccesoDenegadoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { DatosPersonales, PARENTESCO_TITULAR, PerfilPaciente } from '../domain/perfil-paciente';
import { PerfilPacienteRepository } from '../domain/perfil-paciente.repository';

/**
 * «Control» Perfiles. Además de los casos de uso del titular, expone
 * `asegurarGestion()`, la regla que el resto de módulos consulta para saber
 * si un usuario puede actuar en nombre de un paciente.
 */
@Injectable()
export class PerfilesService {
  constructor(
    private readonly perfiles: PerfilPacienteRepository,
    private readonly reloj: Reloj,
  ) {}

  async crearPerfilTitular(usuarioId: string, datos: DatosPersonales): Promise<PerfilPaciente> {
    const perfil = PerfilPaciente.crear(usuarioId, PARENTESCO_TITULAR, datos, this.reloj.ahora());
    await this.perfiles.guardar(perfil);
    return perfil;
  }

  async crearPerfilFamiliar(titularId: string, parentesco: string, datos: DatosPersonales): Promise<PerfilPaciente> {
    if (parentesco.trim().toUpperCase() === PARENTESCO_TITULAR) {
      throw new ReglaNegocioError('Un dependiente no puede tener parentesco TITULAR');
    }
    const existentes = await this.perfiles.buscarPorTitular(titularId);
    if (existentes.length >= 10) throw new ReglaNegocioError('Se alcanzó el máximo de 10 perfiles por cuenta');
    const perfil = PerfilPaciente.crear(titularId, parentesco, datos, this.reloj.ahora());
    await this.perfiles.guardar(perfil);
    return perfil;
  }

  listarPerfiles(titularId: string): Promise<PerfilPaciente[]> {
    return this.perfiles.buscarPorTitular(titularId);
  }

  async actualizar(actor: Actor, pacienteId: string, datos: Partial<DatosPersonales>): Promise<PerfilPaciente> {
    const perfil = await this.asegurarGestion(actor, pacienteId);
    perfil.actualizar(datos, this.reloj.ahora());
    await this.perfiles.guardar(perfil);
    return perfil;
  }

  /**
   * El dependiente, ya mayor de edad y con su propia cuenta, pide el control de su perfil.
   * Se identifica con la cédula y la fecha de nacimiento que cargó su titular.
   */
  async solicitarControl(actor: Actor, cedula: string, fechaNacimiento: Date): Promise<PerfilPaciente> {
    const dia = (f: Date) => f.toISOString().slice(0, 10);
    const perfil = (await this.perfiles.buscarPorCedula(cedula.trim())).find(
      (p) => !p.esTitular && dia(p.fechaNacimiento) === dia(fechaNacimiento),
    );
    if (!perfil) {
      throw new ReglaNegocioError('No encontramos un perfil dependiente con esa cédula y fecha de nacimiento');
    }
    perfil.solicitarControl(actor.id, this.reloj.ahora());
    await this.perfiles.guardar(perfil);
    return perfil;
  }

  /** El titular aprueba (entrega el perfil) o rechaza la solicitud. */
  async responderSolicitudControl(actor: Actor, pacienteId: string, aprobar: boolean): Promise<PerfilPaciente> {
    const perfil = await this.asegurarGestion(actor, pacienteId);
    if (aprobar) perfil.aprobarControl(this.reloj.ahora());
    else perfil.rechazarControl();
    await this.perfiles.guardar(perfil);
    return perfil;
  }

  async obtener(pacienteId: string): Promise<PerfilPaciente> {
    const perfil = await this.perfiles.buscarPorId(pacienteId);
    if (!perfil) throw new NoEncontradoError('Paciente', pacienteId);
    return perfil;
  }

  obtenerVarios(ids: string[]): Promise<PerfilPaciente[]> {
    return ids.length ? this.perfiles.buscarPorIds([...new Set(ids)]) : Promise.resolve([]);
  }

  async puedeGestionar(usuarioId: string, pacienteId: string): Promise<boolean> {
    const perfil = await this.perfiles.buscarPorId(pacienteId);
    return !!perfil && perfil.esGestionadoPor(usuarioId);
  }

  /** Devuelve el perfil si el actor es su titular; si no, lanza 403/404. */
  async asegurarGestion(actor: Actor, pacienteId: string): Promise<PerfilPaciente> {
    const perfil = await this.obtener(pacienteId);
    if (!perfil.esGestionadoPor(actor.id) && !actor.roles.includes(RolUsuario.ADMIN)) {
      throw new AccesoDenegadoError('No gestionas este perfil de paciente');
    }
    return perfil;
  }

  /** Usuario titular al que se notifica todo lo que ocurre con el perfil. */
  async titularDe(pacienteId: string): Promise<string> {
    return (await this.obtener(pacienteId)).titularUsuarioId;
  }
}
