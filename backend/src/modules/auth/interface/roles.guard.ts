import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AccesoDenegadoError } from '../../../shared/domain/errores';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ROLES_REQUERIDOS } from '../../../shared/interface/auth/decoradores';

/** «Boundary» RolesGuard (global): comprueba el rol exigido por el endpoint (RBAC). */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(contexto: ExecutionContext): boolean {
    const requeridos = this.reflector.getAllAndOverride<RolUsuario[]>(ROLES_REQUERIDOS, [
      contexto.getHandler(),
      contexto.getClass(),
    ]);
    if (!requeridos?.length) return true;
    const actor: Actor | undefined = contexto.switchToHttp().getRequest().actor;
    if (!actor) return false;
    if (!requeridos.some((r) => actor.roles.includes(r))) {
      throw new AccesoDenegadoError(`Requiere rol: ${requeridos.join(' o ')}`);
    }
    return true;
  }
}
