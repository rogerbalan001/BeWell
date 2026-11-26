import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'suscripciones_push', versionKey: false })
export class SuscripcionPushDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) usuarioId: Types.ObjectId;
  @Prop({ required: true, unique: true }) endpoint: string;
  @Prop({ required: true }) p256dh: string;
  @Prop({ required: true }) auth: string;
  @Prop({ required: true }) creadaEn: Date;
}
export const SuscripcionPushSchema = SchemaFactory.createForClass(SuscripcionPushDoc);

/** Claves VAPID del servidor: se generan una vez y se conservan para no invalidar las suscripciones. */
@Schema({ collection: 'configuracion_push', versionKey: false })
export class ConfiguracionPushDoc {
  @Prop({ required: true }) _id: string;
  @Prop({ required: true }) publica: string;
  @Prop({ required: true }) privadaCifrada: string;
}
export const ConfiguracionPushSchema = SchemaFactory.createForClass(ConfiguracionPushDoc);
