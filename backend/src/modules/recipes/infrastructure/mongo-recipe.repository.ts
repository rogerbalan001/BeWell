import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { EstadoRecipe, ItemRecipe, RecipeDigital, RecipeRepository } from '../domain/recipe-digital';
import { RecipeDoc } from './recipe.schema';

@Injectable()
export class MongoRecipeRepository extends RecipeRepository {
  constructor(
    @InjectModel(RecipeDoc.name) private readonly modelo: Model<RecipeDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(r: RecipeDigital): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(r.id) },
      {
        _id: oid(r.id),
        citaId: oid(r.citaId),
        medicoId: oid(r.medicoId),
        pacienteId: oid(r.pacienteId),
        contenidoCifrado: this.cifrador.cifrar(JSON.stringify({ items: r.items, diagnostico: r.diagnostico })),
        codigoVerificacion: r.codigoVerificacion,
        emitidoEn: r.emitidoEn,
        validoHasta: r.validoHasta,
        hashContenido: r.hashContenido,
        firma: r.firma,
        llaveFirmaId: r.llaveFirmaId,
        algoritmo: r.algoritmo,
        estado: r.estado,
        motivoAnulacion: r.motivoAnulacion,
        anuladoEn: r.anuladoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<RecipeDigital | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorCodigo(codigo: string): Promise<RecipeDigital | null> {
    const d = await this.modelo.findOne({ codigoVerificacion: codigo }).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPaciente(pacienteId: string): Promise<RecipeDigital[]> {
    return (await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ emitidoEn: -1 }).lean()).map((d) => this.aDominio(d));
  }

  async listarPorMedico(medicoId: string): Promise<RecipeDigital[]> {
    return (await this.modelo.find({ medicoId: oid(medicoId) }).sort({ emitidoEn: -1 }).limit(200).lean()).map((d) => this.aDominio(d));
  }

  private aDominio(d: RecipeDoc): RecipeDigital {
    const contenido = JSON.parse(this.cifrador.descifrar(d.contenidoCifrado)) as { items: ItemRecipe[]; diagnostico?: string };
    return new RecipeDigital({
      id: str(d._id),
      citaId: str(d.citaId),
      medicoId: str(d.medicoId),
      pacienteId: str(d.pacienteId),
      items: contenido.items,
      diagnostico: contenido.diagnostico,
      codigoVerificacion: d.codigoVerificacion,
      emitidoEn: d.emitidoEn,
      validoHasta: d.validoHasta,
      hashContenido: d.hashContenido,
      firma: d.firma,
      llaveFirmaId: d.llaveFirmaId,
      algoritmo: d.algoritmo,
      estado: d.estado as EstadoRecipe,
      motivoAnulacion: d.motivoAnulacion,
      anuladoEn: d.anuladoEn,
    });
  }
}
