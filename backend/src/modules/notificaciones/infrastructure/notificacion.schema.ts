import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'notificaciones', versionKey: false })
export class NotificacionDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) usuarioId: Types.ObjectId;
  @Prop({ required: true }) tipo: string;
  @Prop({ required: true }) titulo: string;
  @Prop({ required: true }) mensaje: string;
  @Prop({ type: Object, default: {} }) datos: Record<string, string>;
  @Prop({ default: false }) leida: boolean;
  @Prop({ required: true }) creadaEn: Date;
}

export const NotificacionSchema = SchemaFactory.createForClass(NotificacionDoc);
NotificacionSchema.index({ usuarioId: 1, creadaEn: -1 });
