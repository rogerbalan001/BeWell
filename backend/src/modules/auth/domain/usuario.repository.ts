import { Usuario } from './usuario';

/** «Repository» de usuarios (colección `usuarios`). */
export abstract class UsuarioRepository {
  abstract guardar(usuario: Usuario): Promise<void>;
  abstract buscarPorId(id: string): Promise<Usuario | null>;
  abstract buscarPorEmail(email: string): Promise<Usuario | null>;
}
