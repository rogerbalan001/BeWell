import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import { Actor, RolUsuario } from '../../domain/roles';

export const ES_PUBLICO = 'bewell:publico';
export const AUTH_OPCIONAL = 'bewell:authOpcional';
export const ROLES_REQUERIDOS = 'bewell:roles';

/** Endpoint accesible sin token (p. ej. verificación de récipes). */
export const Publico = () => SetMetadata(ES_PUBLICO, true);

/** Endpoint público que, si recibe un token válido, identifica al actor (ficha QR). */
export const AuthOpcional = () => SetMetadata(AUTH_OPCIONAL, true);

/** Restringe el endpoint a uno o varios roles (lo aplica RolesGuard). */
export const Roles = (...roles: RolUsuario[]) => SetMetadata(ROLES_REQUERIDOS, roles);

/** Inyecta el actor autenticado que JwtAuthGuard dejó en la solicitud. */
export const ActorActual = createParamDecorator((_dato: unknown, ctx: ExecutionContext): Actor | undefined => {
  return ctx.switchToHttp().getRequest().actor;
});
