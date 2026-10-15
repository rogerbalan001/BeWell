import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { AuditoriaRepository, RegistroAuditoriaEntidad } from '../domain/registro-auditoria';
import { RegistroAuditoriaDoc } from './auditoria.schema';

@Injectable()
export class MongoAuditoriaRepository extends AuditoriaRepository {
  constructor(@InjectModel(RegistroAuditoriaDoc.name) private readonly modelo: Model<RegistroAuditoriaDoc>) {
    super();
  }

  async insertar(r: RegistroAuditoriaEntidad): Promise<void> {
    await this.modelo.create({
      _id: oid(r.id),
      ...r.entrada,
      actorId: oidOpcional(r.entrada.actorId),
      pacienteId: oidOpcional(r.entrada.pacienteId),
      fecha: r.fecha,
    });
  }

  async listarPorPaciente(pacienteId: string, limite: number): Promise<RegistroAuditoriaEntidad[]> {
    const docs = await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ fecha: -1 }).limit(limite).lean();
    return docs.map(
      (d) =>
        new RegistroAuditoriaEntidad(
          str(d._id),
          {
            actorId: strOpcional(d.actorId),
            rolActor: d.rolActor,
            accion: d.accion,
            recurso: d.recurso,
            recursoId: d.recursoId,
            pacienteId: strOpcional(d.pacienteId),
            accesoEmergencia: d.accesoEmergencia,
          },
          d.fecha,
        ),
    );
  }
}
