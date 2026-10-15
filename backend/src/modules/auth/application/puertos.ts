import { Actor } from '../../../shared/domain/roles';

/** Puerto de hash de contraseñas (Argon2id en infraestructura). */
export abstract class PasswordHasher {
  abstract hash(password: string): Promise<string>;
  abstract verificar(hash: string, password: string): Promise<boolean>;
}

export interface ParTokens {
  accessToken: string;
  refreshToken: string;
}

export interface CargaRefresh {
  usuarioId: string;
  versionSesion: number;
}

/** Puerto de emisión y validación de tokens (JWT en infraestructura). */
export abstract class EmisorTokens {
  abstract emitir(actor: Actor, versionSesion: number): Promise<ParTokens>;
  abstract verificarAcceso(token: string): Promise<Actor>;
  abstract verificarRefresh(token: string): Promise<CargaRefresh>;
}
