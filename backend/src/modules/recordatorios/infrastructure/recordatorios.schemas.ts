import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'preferencias_recordatorio', versionKey: false })
export class PreferenciasRecordatorioDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) usuarioId: Types.ObjectId;
  @Prop({ required: true }) citas: boolean;
  @Prop({ required: true }) medicamentos: boolean;
  @Prop({ required: true }) examenes: boolean;
  @Prop({ required: true }) actualizadoEn: Date;
}
export const PreferenciasRecordatorioSchema = SchemaFactory.createForClass(PreferenciasRecordatorioDoc);

/** Un documento por recordatorio enviado; la clave única evita duplicados. */
@Schema({ collection: 'recordatorios_enviados', versionKey: false })
export class RecordatorioEnviadoDoc {
  _id: Types.ObjectId;
  @Prop({ required: true, unique: true }) clave: string;
  @Prop({ required: true }) enviadoEn: Date;
}
export const RecordatorioEnviadoSchema = SchemaFactory.createForClass(RecordatorioEnviadoDoc);
// Se borran solos a los 180 días: para entonces ya no hay nada que deduplicar.
RecordatorioEnviadoSchema.index({ enviadoEn: 1 }, { expireAfterSeconds: 180 * 24 * 3600 });
