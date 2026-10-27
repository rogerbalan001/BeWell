import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { PreferenciasRecordatorio } from '../domain/preferencias-recordatorio';
import { PreferenciasRecordatorioRepository, RegistroEnviosRepository } from '../domain/repositorios';
import { PreferenciasRecordatorioDoc, RecordatorioEnviadoDoc } from './recordatorios.schemas';

@Injectable()
export class MongoPreferenciasRecordatorioRepository extends PreferenciasRecordatorioRepository {
  constructor(@InjectModel(PreferenciasRecordatorioDoc.name) private readonly modelo: Model<PreferenciasRecordatorioDoc>) {
    super();
  }

  async buscar(usuarioId: string): Promise<PreferenciasRecordatorio | null> {
    const d = await this.modelo.findOne({ usuarioId: oid(usuarioId) }).lean();
    return d ? new PreferenciasRecordatorio(str(d.usuarioId), d.citas, d.medicamentos, d.examenes, d.actualizadoEn) : null;
  }

  async guardar(p: PreferenciasRecordatorio): Promise<void> {
    await this.modelo.updateOne(
      { usuarioId: oid(p.usuarioId) },
      { $set: { citas: p.citas, medicamentos: p.medicamentos, examenes: p.examenes, actualizadoEn: p.actualizadoEn } },
      { upsert: true },
    );
  }
}

/** Código de MongoDB para "clave duplicada". */
const CLAVE_DUPLICADA = 11000;

@Injectable()
export class MongoRegistroEnviosRepository extends RegistroEnviosRepository {
  constructor(@InjectModel(RecordatorioEnviadoDoc.name) private readonly modelo: Model<RecordatorioEnviadoDoc>) {
    super();
  }

  async registrarSiNuevo(clave: string, ahora: Date): Promise<boolean> {
    try {
      await this.modelo.create({ clave, enviadoEn: ahora });
      return true;
    } catch (e) {
      if ((e as { code?: number }).code === CLAVE_DUPLICADA) return false;
      throw e;
    }
  }
}
