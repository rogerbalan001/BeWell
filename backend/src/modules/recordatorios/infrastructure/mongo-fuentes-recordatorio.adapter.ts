import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { EstadoCita } from '../../citas/domain/cita';
import { CitaDoc } from '../../citas/infrastructure/cita.schema';
import { EstadoSolicitud } from '../../examenes/domain/solicitud-examen';
import { SolicitudExamenDoc } from '../../examenes/infrastructure/examenes.schemas';
import { EstadoRecipe, ItemRecipe } from '../../recipes/domain/recipe-digital';
import { RecipeDoc } from '../../recipes/infrastructure/recipe.schema';
import { CitaParaRecordar, FuentesRecordatorio, OrdenParaRecordar, RecipeParaRecordar } from '../application/fuentes-recordatorio';

const filtroPacientes = (ids?: string[]) => (ids ? { pacienteId: { $in: ids.map(oid) } } : {});

/**
 * Lectura (solo lectura) de las colecciones de citas, récipes y órdenes de
 * exámenes para calcular recordatorios. Leer directamente evita cargar los
 * agregados completos cada 5 minutos; ninguna escritura sale de aquí.
 */
@Injectable()
export class MongoFuentesRecordatorioAdapter extends FuentesRecordatorio {
  constructor(
    @InjectModel(CitaDoc.name) private readonly citas: Model<CitaDoc>,
    @InjectModel(RecipeDoc.name) private readonly recipes: Model<RecipeDoc>,
    @InjectModel(SolicitudExamenDoc.name) private readonly ordenes: Model<SolicitudExamenDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async citasConfirmadasEntre(desde: Date, hasta: Date, pacienteIds?: string[]): Promise<CitaParaRecordar[]> {
    const docs = await this.citas
      .find({ estado: EstadoCita.CONFIRMADA, inicio: { $gt: desde, $lte: hasta }, ...filtroPacientes(pacienteIds) })
      .select({ pacienteId: 1, medicoId: 1, inicio: 1, modalidad: 1 })
      .lean();
    return docs.map((d) => ({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      inicio: d.inicio,
      modalidad: d.modalidad,
    }));
  }

  async recipesVigentes(emitidosDesde: Date, pacienteIds?: string[]): Promise<RecipeParaRecordar[]> {
    const docs = await this.recipes
      .find({ estado: EstadoRecipe.VIGENTE, emitidoEn: { $gte: emitidosDesde }, ...filtroPacientes(pacienteIds) })
      .select({ pacienteId: 1, emitidoEn: 1, contenidoCifrado: 1 })
      .lean();
    return docs.map((d) => {
      const { items } = JSON.parse(this.cifrador.descifrar(d.contenidoCifrado)) as { items: ItemRecipe[] };
      return { id: str(d._id), pacienteId: str(d.pacienteId), emitidoEn: d.emitidoEn, items };
    });
  }

  async ordenesPendientes(creadasDesde: Date, pacienteIds?: string[]): Promise<OrdenParaRecordar[]> {
    const docs = await this.ordenes
      .find({ estado: EstadoSolicitud.PENDIENTE, creadaEn: { $gte: creadasDesde }, ...filtroPacientes(pacienteIds) })
      .select({ pacienteId: 1, examenes: 1, creadaEn: 1 })
      .lean();
    return docs.map((d) => ({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      examenes: d.examenes,
      creadaEn: d.creadaEn,
    }));
  }
}
