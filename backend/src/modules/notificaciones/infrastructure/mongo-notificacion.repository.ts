import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { Notificacion, NotificacionRepository } from '../domain/notificacion';
import { NotificacionDoc } from './notificacion.schema';

@Injectable()
export class MongoNotificacionRepository extends NotificacionRepository {
  constructor(@InjectModel(NotificacionDoc.name) private readonly modelo: Model<NotificacionDoc>) {
    super();
  }

  async guardar(n: Notificacion): Promise<void> {
    await this.modelo.create({
      _id: oid(n.id),
      usuarioId: oid(n.usuarioId),
      tipo: n.tipo,
      titulo: n.titulo,
      mensaje: n.mensaje,
      datos: n.datos,
      leida: n.leida,
      creadaEn: n.creadaEn,
    });
  }

  async listarPorUsuario(usuarioId: string, limite: number): Promise<Notificacion[]> {
    const docs = await this.modelo.find({ usuarioId: oid(usuarioId) }).sort({ creadaEn: -1 }).limit(limite).lean();
    return docs.map((d) => new Notificacion(str(d._id), str(d.usuarioId), d.tipo, d.titulo, d.mensaje, d.datos ?? {}, d.leida, d.creadaEn));
  }

  async marcarLeida(usuarioId: string, id: string): Promise<void> {
    await this.modelo.updateOne({ _id: oid(id), usuarioId: oid(usuarioId) }, { $set: { leida: true } });
  }

  async marcarTodasLeidas(usuarioId: string): Promise<void> {
    await this.modelo.updateMany({ usuarioId: oid(usuarioId), leida: false }, { $set: { leida: true } });
  }

  contarNoLeidas(usuarioId: string): Promise<number> {
    return this.modelo.countDocuments({ usuarioId: oid(usuarioId), leida: false });
  }
}
