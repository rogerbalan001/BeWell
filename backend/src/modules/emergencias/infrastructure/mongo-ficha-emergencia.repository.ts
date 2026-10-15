import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { CampoFicha, FichaEmergencia, FichaEmergenciaRepository } from '../domain/ficha-emergencia';
import { FichaEmergenciaDoc } from './ficha-emergencia.schema';

@Injectable()
export class MongoFichaEmergenciaRepository extends FichaEmergenciaRepository {
  constructor(
    @InjectModel(FichaEmergenciaDoc.name) private readonly modelo: Model<FichaEmergenciaDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(f: FichaEmergencia): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(f.id) },
      {
        _id: oid(f.id),
        pacienteId: oid(f.pacienteId),
        tokenQrHash: f.tokenQrHash,
        qrGeneradoEn: f.qrGeneradoEn,
        grupoSanguineo: f.grupoSanguineo,
        alergias: f.alergias,
        condicionesCronicas: this.cifrador.cifrarLista(f.condicionesCronicas),
        medicacionActual: this.cifrador.cifrarLista(f.medicacionActual),
        contactos: f.contactos,
        camposPublicos: f.camposPublicos,
        actualizadoEn: f.actualizadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorPaciente(pacienteId: string): Promise<FichaEmergencia | null> {
    const d = await this.modelo.findOne({ pacienteId: oid(pacienteId) }).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorTokenHash(hash: string): Promise<FichaEmergencia | null> {
    const d = await this.modelo.findOne({ tokenQrHash: hash }).lean();
    return d ? this.aDominio(d) : null;
  }

  private aDominio(d: FichaEmergenciaDoc): FichaEmergencia {
    return new FichaEmergencia({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      tokenQrHash: d.tokenQrHash,
      qrGeneradoEn: d.qrGeneradoEn,
      grupoSanguineo: d.grupoSanguineo,
      alergias: d.alergias ?? [],
      condicionesCronicas: this.cifrador.descifrarLista(d.condicionesCronicas),
      medicacionActual: this.cifrador.descifrarLista(d.medicacionActual),
      contactos: (d.contactos ?? []).map((c) => ({ nombre: c.nombre, parentesco: c.parentesco, telefono: c.telefono })),
      camposPublicos: (d.camposPublicos ?? []) as CampoFicha[],
      actualizadoEn: d.actualizadoEn,
    });
  }
}
