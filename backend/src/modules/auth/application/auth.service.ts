import { Injectable } from '@nestjs/common';
import { Centavos } from '../../../shared/domain/dinero';
import { ConflictoError, NoAutenticadoError, NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { DatosPersonales } from '../../perfiles/domain/perfil-paciente';
import { Usuario, validarPassword } from '../domain/usuario';
import { UsuarioRepository } from '../domain/usuario.repository';
import { EmisorTokens, ParTokens, PasswordHasher } from './puertos';

export interface Sesion extends ParTokens {
  usuario: {
    id: string;
    email: string;
    roles: RolUsuario[];
    nombreMostrado: string;
    medicoId?: string;
  };
}

/** «Control» de autenticación: registro, inicio de sesión, renovación y cierre. */
@Injectable()
export class AuthService {
  private hashSenuelo?: Promise<string>;

  constructor(
    private readonly usuarios: UsuarioRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: EmisorTokens,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly reloj: Reloj,
  ) {}

  /** Registro de paciente: crea el usuario titular y su propio perfil. */
  async registrarPaciente(datos: { email: string; password: string; telefono?: string } & DatosPersonales): Promise<Sesion> {
    const usuario = await this.crearUsuario(datos.email, datos.password, [RolUsuario.PACIENTE], `${datos.nombres} ${datos.apellidos}`, datos.telefono);
    await this.perfiles.crearPerfilTitular(usuario.id, datos);
    return this.iniciar(usuario);
  }

  /** Registro de médico: queda PENDIENTE hasta que el administrador valide sus credenciales. */
  async registrarMedico(datos: {
    email: string;
    password: string;
    telefono?: string;
    nombres: string;
    apellidos: string;
    especialidades: string[];
    tarifaConsulta: Centavos;
  }): Promise<Sesion> {
    const usuario = await this.crearUsuario(datos.email, datos.password, [RolUsuario.MEDICO], `${datos.nombres} ${datos.apellidos}`, datos.telefono);
    await this.medicos.registrarMedico(usuario.id, datos);
    return this.iniciar(usuario);
  }

  /** Alta de usuarios internos (ADMIN, PERSONAL_EMERGENCIA). Lo usa el seed. */
  async crearUsuarioInterno(email: string, password: string, rol: RolUsuario, nombre: string): Promise<Usuario> {
    return this.crearUsuario(email, password, [rol], nombre);
  }

  async iniciarSesion(email: string, password: string): Promise<Sesion> {
    const usuario = await this.usuarios.buscarPorEmail(Usuario.normalizarEmail(email));
    // Se verifica el hash aunque el usuario no exista para no filtrar su existencia por tiempo de respuesta.
    this.hashSenuelo ??= this.hasher.hash('senuelo-bewell-2026');
    const valido = await this.hasher.verificar(usuario ? usuario.passwordHash : await this.hashSenuelo, password);
    if (!usuario || !valido || !usuario.activo) throw new NoAutenticadoError('Correo o contraseña incorrectos');
    return this.iniciar(usuario);
  }

  async refrescar(refreshToken: string): Promise<Sesion> {
    const carga = await this.tokens.verificarRefresh(refreshToken);
    const usuario = await this.usuarios.buscarPorId(carga.usuarioId);
    if (!usuario || !usuario.activo || usuario.versionSesion !== carga.versionSesion) {
      throw new NoAutenticadoError('La sesión expiró, inicia sesión de nuevo');
    }
    return this.iniciar(usuario);
  }

  async cerrarSesion(usuarioId: string): Promise<void> {
    const usuario = await this.usuarios.buscarPorId(usuarioId);
    if (!usuario) return;
    usuario.revocarSesiones();
    await this.usuarios.guardar(usuario);
  }

  async obtenerUsuario(id: string): Promise<Usuario> {
    const usuario = await this.usuarios.buscarPorId(id);
    if (!usuario) throw new NoEncontradoError('Usuario', id);
    return usuario;
  }

  validarAcceso(token: string): Promise<Actor> {
    return this.tokens.verificarAcceso(token);
  }

  private async crearUsuario(email: string, password: string, roles: RolUsuario[], nombre: string, telefono?: string): Promise<Usuario> {
    validarPassword(password);
    if (await this.usuarios.buscarPorEmail(Usuario.normalizarEmail(email))) {
      throw new ConflictoError('Ya existe una cuenta con ese correo');
    }
    const usuario = Usuario.crear({ email, passwordHash: await this.hasher.hash(password), roles, nombreMostrado: nombre, telefono }, this.reloj.ahora());
    await this.usuarios.guardar(usuario);
    return usuario;
  }

  private async iniciar(usuario: Usuario): Promise<Sesion> {
    const medico = usuario.roles.includes(RolUsuario.MEDICO) ? await this.medicos.buscarPorUsuario(usuario.id) : null;
    const actor: Actor = { id: usuario.id, email: usuario.email, roles: usuario.roles, medicoId: medico?.id };
    const par = await this.tokens.emitir(actor, usuario.versionSesion);
    return {
      ...par,
      usuario: { id: usuario.id, email: usuario.email, roles: usuario.roles, nombreMostrado: usuario.nombreMostrado, medicoId: medico?.id },
    };
  }
}
