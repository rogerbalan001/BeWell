import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { RolUsuario } from '../../../shared/domain/roles';

export interface PropsUsuario {
  id: string;
  email: string;
  passwordHash: string;
  roles: RolUsuario[];
  nombreMostrado: string;
  telefono?: string;
  mfaHabilitado: boolean;
  activo: boolean;
  /** Se incrementa al cerrar sesión: invalida todos los refresh tokens emitidos. */
  versionSesion: number;
  creadoEn: Date;
}

/** «Entity» Usuario: identidad y credenciales de acceso. */
export class Usuario implements PropsUsuario {
  id: string;
  email: string;
  passwordHash: string;
  roles: RolUsuario[];
  nombreMostrado: string;
  telefono?: string;
  mfaHabilitado: boolean;
  activo: boolean;
  versionSesion: number;
  creadoEn: Date;

  constructor(props: PropsUsuario) {
    Object.assign(this, props);
  }

  static crear(datos: { email: string; passwordHash: string; roles: RolUsuario[]; nombreMostrado: string; telefono?: string }, ahora: Date): Usuario {
    const email = Usuario.normalizarEmail(datos.email);
    asegurar(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email), 'Correo electrónico inválido');
    asegurar(datos.roles.length > 0, 'El usuario debe tener al menos un rol');
    return new Usuario({
      id: generarId(),
      email,
      passwordHash: datos.passwordHash,
      roles: datos.roles,
      nombreMostrado: datos.nombreMostrado,
      telefono: datos.telefono,
      mfaHabilitado: false,
      activo: true,
      versionSesion: 0,
      creadoEn: ahora,
    });
  }

  static normalizarEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  revocarSesiones(): void {
    this.versionSesion += 1;
  }
}

/** Política de contraseñas: mínimo 8 caracteres con letras y números. */
export function validarPassword(password: string): void {
  asegurar(typeof password === 'string' && password.length >= 8, 'La contraseña debe tener al menos 8 caracteres');
  asegurar(/[A-Za-z]/.test(password) && /\d/.test(password), 'La contraseña debe combinar letras y números');
}
