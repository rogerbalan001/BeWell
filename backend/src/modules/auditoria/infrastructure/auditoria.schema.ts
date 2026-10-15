import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'auditoria', versionKey: false })
export class RegistroAuditoriaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) actorId?: Types.ObjectId;
  @Prop({ required: true }) rolActor: string;
  @Prop({ required: true }) accion: string;
  @Prop({ required: true }) recurso: string;
  @Prop() recursoId?: string;
  @Prop({ type: Types.ObjectId }) pacienteId?: Types.ObjectId;
  @Prop({ default: false }) accesoEmergencia: boolean;
  @Prop() ip?: string;
  @Prop({ required: true }) fecha: Date;
}

export const RegistroAuditoriaSchema = SchemaFactory.createForClass(RegistroAuditoriaDoc);
RegistroAuditoriaSchema.index({ pacienteId: 1, fecha: -1 });
RegistroAuditoriaSchema.index({ actorId: 1, fecha: -1 });
