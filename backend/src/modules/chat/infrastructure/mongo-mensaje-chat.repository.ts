import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { AutorChat, MensajeChat } from '../domain/mensaje-chat';
import { MensajeChatRepository, NoLeidosPorCita } from '../domain/mensaje-chat.repository';
import { MensajeChatDoc } from './mensaje-chat.schema';

@Injectable()
export class MongoMensajeChatRepository extends MensajeChatRepository {
  constructor(
    @InjectModel(MensajeChatDoc.name) private readonly modelo: Model<MensajeChatDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(m: MensajeChat): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(m.id) },
      {
        _id: oid(m.id),
        citaId: oid(m.citaId),
        autor: m.autor,
        autorUsuarioId: oid(m.autorUsuarioId),
        destinatarioUsuarioId: oid(m.destinatarioUsuarioId),
        textoCifrado: this.cifrador.cifrar(m.texto),
        enviadoEn: m.enviadoEn,
        leidoEn: m.leidoEn,
      },
      { upsert: true },
    );
  }

  async listarPorCita(citaId: string, despuesDe?: Date, limite = 200): Promise<MensajeChat[]> {
    const filtro = { citaId: oid(citaId), ...(despuesDe ? { enviadoEn: { $gt: despuesDe } } : {}) };
    // Los últimos `limite` mensajes, devueltos del más antiguo al más reciente.
    const docs = await this.modelo.find(filtro).sort({ enviadoEn: -1 }).limit(limite).lean();
    return docs.reverse().map((d) => this.aDominio(d));
  }

  async marcarLeidos(citaId: string, destinatarioUsuarioId: string, ahora: Date): Promise<number> {
    const r = await this.modelo.updateMany(
      { citaId: oid(citaId), destinatarioUsuarioId: oid(destinatarioUsuarioId), leidoEn: { $exists: false } },
      { $set: { leidoEn: ahora } },
    );
    return r.modifiedCount;
  }

  async contarNoLeidos(destinatarioUsuarioId: string): Promise<NoLeidosPorCita[]> {
    const filas = await this.modelo.aggregate<{ _id: unknown; noLeidos: number }>([
      { $match: { destinatarioUsuarioId: oid(destinatarioUsuarioId), leidoEn: { $exists: false } } },
      { $group: { _id: '$citaId', noLeidos: { $sum: 1 } } },
    ]);
    return filas.map((f) => ({ citaId: str(f._id), noLeidos: f.noLeidos }));
  }

  private aDominio(d: MensajeChatDoc): MensajeChat {
    return new MensajeChat({
      id: str(d._id),
      citaId: str(d.citaId),
      autor: d.autor as AutorChat,
      autorUsuarioId: str(d.autorUsuarioId),
      destinatarioUsuarioId: str(d.destinatarioUsuarioId),
      texto: this.cifrador.descifrar(d.textoCifrado),
      enviadoEn: d.enviadoEn,
      leidoEn: d.leidoEn,
    });
  }
}
