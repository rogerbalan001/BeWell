import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RolUsuario } from '../../../shared/domain/roles';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { Usuario } from '../domain/usuario';
import { UsuarioRepository } from '../domain/usuario.repository';
import { UsuarioDoc } from './usuario.schema';

@Injectable()
export class MongoUsuarioRepository extends UsuarioRepository {
  constructor(@InjectModel(UsuarioDoc.name) private readonly modelo: Model<UsuarioDoc>) {
    super();
  }

  async guardar(u: Usuario): Promise<void> {
    const { id, ...resto } = u;
    await this.modelo.replaceOne({ _id: oid(id) }, { _id: oid(id), ...resto }, { upsert: true });
  }

  async buscarPorId(id: string): Promise<Usuario | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorEmail(email: string): Promise<Usuario | null> {
    const d = await this.modelo.findOne({ email }).lean();
    return d ? this.aDominio(d) : null;
  }

  private aDominio(d: UsuarioDoc): Usuario {
    return new Usuario({
      id: str(d._id),
      email: d.email,
      passwordHash: d.passwordHash,
      roles: d.roles as RolUsuario[],
      nombreMostrado: d.nombreMostrado,
      telefono: d.telefono,
      mfaHabilitado: d.mfaHabilitado,
      activo: d.activo,
      versionSesion: d.versionSesion ?? 0,
      creadoEn: d.creadoEn,
    });
  }
}
