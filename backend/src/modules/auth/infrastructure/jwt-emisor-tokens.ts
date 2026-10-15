import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { NoAutenticadoError } from '../../../shared/domain/errores';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { CargaRefresh, EmisorTokens, ParTokens } from '../application/puertos';

interface CargaAcceso {
  sub: string;
  email: string;
  roles: RolUsuario[];
  medicoId?: string;
  typ: 'access';
}

/** Tokens JWT: acceso de vida corta (API sin estado) y refresh con versión de sesión. */
@Injectable()
export class JwtEmisorTokens extends EmisorTokens {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {
    super();
  }

  async emitir(actor: Actor, versionSesion: number): Promise<ParTokens> {
    const acceso: CargaAcceso = { sub: actor.id, email: actor.email, roles: actor.roles, medicoId: actor.medicoId, typ: 'access' };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(acceso, {
        secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: this.config.get<string>('JWT_ACCESS_TTL') ?? '15m',
      } as never),
      this.jwt.signAsync({ sub: actor.id, ver: versionSesion, typ: 'refresh' }, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.config.get<string>('JWT_REFRESH_TTL') ?? '7d',
      } as never),
    ]);
    return { accessToken, refreshToken };
  }

  async verificarAcceso(token: string): Promise<Actor> {
    try {
      const c = await this.jwt.verifyAsync<CargaAcceso>(token, { secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET') });
      if (c.typ !== 'access') throw new Error('tipo');
      return { id: c.sub, email: c.email, roles: c.roles, medicoId: c.medicoId };
    } catch {
      throw new NoAutenticadoError('Token de acceso inválido o vencido');
    }
  }

  async verificarRefresh(token: string): Promise<CargaRefresh> {
    try {
      const c = await this.jwt.verifyAsync<{ sub: string; ver: number; typ: string }>(token, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
      if (c.typ !== 'refresh') throw new Error('tipo');
      return { usuarioId: c.sub, versionSesion: c.ver };
    } catch {
      throw new NoAutenticadoError('La sesión expiró, inicia sesión de nuevo');
    }
  }
}
