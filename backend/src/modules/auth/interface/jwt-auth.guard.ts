import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { NoAutenticadoError } from '../../../shared/domain/errores';
import { Actor } from '../../../shared/domain/roles';
import { AUTH_OPCIONAL, ES_PUBLICO } from '../../../shared/interface/auth/decoradores';
import { EmisorTokens } from '../application/puertos';

/**
 * «Boundary» JwtAuthGuard (global). Valida el token de acceso en cada
 * solicitud y deja el actor en `request.actor`. Los endpoints @Publico() lo
 * omiten; los @AuthOpcional() identifican al actor solo si envía token.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly tokens: EmisorTokens,
  ) {}

  async canActivate(contexto: ExecutionContext): Promise<boolean> {
    const objetivos = [contexto.getHandler(), contexto.getClass()];
    const publico = this.reflector.getAllAndOverride<boolean>(ES_PUBLICO, objetivos);
    const opcional = this.reflector.getAllAndOverride<boolean>(AUTH_OPCIONAL, objetivos);
    const req = contexto.switchToHttp().getRequest<Request & { actor?: Actor }>();
    const token = this.extraerToken(req);

    if (publico) return true;
    if (opcional) {
      if (token) req.actor = await this.tokens.verificarAcceso(token).catch(() => undefined);
      return true;
    }
    if (!token) throw new NoAutenticadoError('Falta el token de acceso');
    req.actor = await this.tokens.verificarAcceso(token);
    return true;
  }

  private extraerToken(req: Request): string | undefined {
    const [tipo, token] = (req.headers.authorization ?? '').split(' ');
    return tipo === 'Bearer' && token ? token : undefined;
  }
}
