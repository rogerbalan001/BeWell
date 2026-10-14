export enum RolUsuario {
  PACIENTE = 'PACIENTE',
  MEDICO = 'MEDICO',
  ADMIN = 'ADMIN',
  PERSONAL_EMERGENCIA = 'PERSONAL_EMERGENCIA',
}

/** Actor autenticado que ejecuta un caso de uso (extraído del JWT). */
export interface Actor {
  id: string;
  email: string;
  roles: RolUsuario[];
  /** Presente si el usuario tiene perfil de médico. */
  medicoId?: string;
}

export const tieneRol = (actor: Actor | undefined, rol: RolUsuario): boolean =>
  !!actor && actor.roles.includes(rol);
