import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { EstadisticasMedico, ResenaRepository, ResenaVerificada } from '../domain/resena-verificada';
import { ResenaDoc } from './resena.schema';

const redondear = (n: number | null | undefined): number => Math.round((n ?? 0) * 10) / 10;

@Injectable()
export class MongoResenaRepository extends ResenaRepository {
  constructor(@InjectModel(ResenaDoc.name) private readonly modelo: Model<ResenaDoc>) {
    super();
  }

  async guardar(r: ResenaVerificada): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(r.id) },
      {
        _id: oid(r.id),
        citaId: oid(r.citaId),
        pacienteId: oid(r.pacienteId),
        medicoId: oid(r.medicoId),
        autorUsuarioId: oid(r.autorUsuarioId),
        puntualidad: r.puntualidad,
        trato: r.trato,
        claridad: r.claridad,
        instalaciones: r.instalaciones,
        comentario: r.comentario,
        publicadaEn: r.publicadaEn,
        editadaEn: r.editadaEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<ResenaVerificada | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorCita(citaId: string): Promise<ResenaVerificada | null> {
    const d = await this.modelo.findOne({ citaId: oid(citaId) }).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorMedico(medicoId: string, limite: number): Promise<ResenaVerificada[]> {
    const docs = await this.modelo.find({ medicoId: oid(medicoId) }).sort({ publicadaEn: -1 }).limit(limite).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async estadisticas(medicoId: string): Promise<EstadisticasMedico> {
    const [r] = await this.modelo.aggregate<{
      total: number;
      puntualidad: number;
      trato: number;
      claridad: number;
      instalaciones: number;
    }>([
      { $match: { medicoId: oid(medicoId) } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          puntualidad: { $avg: '$puntualidad' },
          trato: { $avg: '$trato' },
          claridad: { $avg: '$claridad' },
          instalaciones: { $avg: '$instalaciones' },
        },
      },
    ]);
    if (!r) return { total: 0, promedio: 0, puntualidad: 0, trato: 0, claridad: 0, instalaciones: 0 };
    return {
      total: r.total,
      promedio: redondear((r.puntualidad + r.trato + r.claridad + r.instalaciones) / 4),
      puntualidad: redondear(r.puntualidad),
      trato: redondear(r.trato),
      claridad: redondear(r.claridad),
      instalaciones: redondear(r.instalaciones),
    };
  }

  private aDominio(d: ResenaDoc): ResenaVerificada {
    return new ResenaVerificada({
      id: str(d._id),
      citaId: str(d.citaId),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      autorUsuarioId: str(d.autorUsuarioId),
      puntualidad: d.puntualidad,
      trato: d.trato,
      claridad: d.claridad,
      instalaciones: d.instalaciones,
      comentario: d.comentario,
      publicadaEn: d.publicadaEn,
      editadaEn: d.editadaEn,
    });
  }
}
