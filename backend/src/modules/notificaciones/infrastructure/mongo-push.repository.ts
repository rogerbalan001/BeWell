import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid } from '../../../shared/infrastructure/mongo/mongo.utils';
import { PushRepository } from '../domain/push';
import { ConfiguracionPushDoc, SuscripcionPushDoc } from './push.schemas';
import { ClavesVapid, SuscripcionPush } from './web-push';

const ID_CLAVES = 'vapid';

@Injectable()
export class MongoPushRepository extends PushRepository {
  constructor(
    @InjectModel(SuscripcionPushDoc.name) private readonly suscripciones: Model<SuscripcionPushDoc>,
    @InjectModel(ConfiguracionPushDoc.name) private readonly configuracion: Model<ConfiguracionPushDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardarSuscripcion(usuarioId: string, s: SuscripcionPush, ahora: Date): Promise<void> {
    await this.suscripciones.updateOne(
      { endpoint: s.endpoint },
      { $set: { usuarioId: oid(usuarioId), p256dh: s.p256dh, auth: s.auth, creadaEn: ahora } },
      { upsert: true },
    );
  }

  async eliminarSuscripcion(endpoint: string): Promise<void> {
    await this.suscripciones.deleteOne({ endpoint });
  }

  async suscripcionesDe(usuarioId: string): Promise<SuscripcionPush[]> {
    const docs = await this.suscripciones.find({ usuarioId: oid(usuarioId) }).lean();
    return docs.map((d) => ({ endpoint: d.endpoint, p256dh: d.p256dh, auth: d.auth }));
  }

  async obtenerClaves(): Promise<ClavesVapid | null> {
    const doc = await this.configuracion.findById(ID_CLAVES).lean();
    return doc ? { publica: doc.publica, privada: this.cifrador.descifrar(doc.privadaCifrada) } : null;
  }

  async guardarClaves(claves: ClavesVapid): Promise<void> {
    await this.configuracion.updateOne(
      { _id: ID_CLAVES },
      { $set: { publica: claves.publica, privadaCifrada: this.cifrador.cifrar(claves.privada) } },
      { upsert: true },
    );
  }
}
