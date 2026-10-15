import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'resenas', versionKey: false })
export class ResenaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) citaId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) autorUsuarioId: Types.ObjectId;
  @Prop({ required: true, min: 1, max: 5 }) puntualidad: number;
  @Prop({ required: true, min: 1, max: 5 }) trato: number;
  @Prop({ required: true, min: 1, max: 5 }) claridad: number;
  @Prop({ required: true, min: 1, max: 5 }) instalaciones: number;
  @Prop() comentario?: string;
  @Prop({ required: true }) publicadaEn: Date;
  @Prop() editadaEn?: Date;
}

export const ResenaSchema = SchemaFactory.createForClass(ResenaDoc);
