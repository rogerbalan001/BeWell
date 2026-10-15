import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'recipes', versionKey: false })
export class RecipeDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) citaId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) pacienteId: Types.ObjectId;
  /** Ítems y diagnóstico cifrados a nivel de campo (JSON). */
  @Prop({ required: true }) contenidoCifrado: string;
  @Prop({ required: true, unique: true }) codigoVerificacion: string;
  @Prop({ required: true }) emitidoEn: Date;
  @Prop({ required: true }) validoHasta: Date;
  @Prop({ required: true }) hashContenido: string;
  @Prop({ required: true }) firma: string;
  @Prop({ required: true }) llaveFirmaId: string;
  @Prop({ required: true }) algoritmo: string;
  @Prop({ required: true }) estado: string;
  @Prop() motivoAnulacion?: string;
  @Prop() anuladoEn?: Date;
}

export const RecipeSchema = SchemaFactory.createForClass(RecipeDoc);
