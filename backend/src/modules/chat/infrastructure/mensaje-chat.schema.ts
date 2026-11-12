import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

/** Un documento por mensaje; el texto se guarda cifrado (decisión D9). */
@Schema({ collection: 'mensajes_chat', versionKey: false })
export class MensajeChatDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) citaId: Types.ObjectId;
  @Prop({ required: true }) autor: string;
  @Prop({ type: Types.ObjectId, required: true }) autorUsuarioId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) destinatarioUsuarioId: Types.ObjectId;
  @Prop({ required: true }) textoCifrado: string;
  @Prop({ required: true }) enviadoEn: Date;
  @Prop() leidoEn?: Date;
}

export const MensajeChatSchema = SchemaFactory.createForClass(MensajeChatDoc);
MensajeChatSchema.index({ citaId: 1, enviadoEn: 1 });
MensajeChatSchema.index({ destinatarioUsuarioId: 1, leidoEn: 1 });
