import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'examenes', versionKey: false })
export class ExamenDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, index: true }) solicitudId?: Types.ObjectId;
  @Prop({ required: true }) titulo: string;
  @Prop() fechaExamen?: Date;
  @Prop({ required: true }) archivoRef: string;
  @Prop({ required: true }) tipoMime: string;
  @Prop({ required: true }) nombreArchivo: string;
  @Prop({ required: true }) tamanoBytes: number;
  @Prop({ required: true }) estadoExtraccion: string;
  /** Resultados cifrados a nivel de campo (JSON). */
  @Prop() resultadosCifrados?: string;
  @Prop({ type: Types.ObjectId, required: true }) cargadoPorUsuarioId: Types.ObjectId;
  @Prop({ required: true }) cargadoEn: Date;
  @Prop({ type: Types.ObjectId }) validadoPorMedicoId?: Types.ObjectId;
}
export const ExamenSchema = SchemaFactory.createForClass(ExamenDoc);
ExamenSchema.index({ pacienteId: 1, cargadoEn: -1 });

@Schema({ collection: 'solicitudes_examen', versionKey: false })
export class SolicitudExamenDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) citaId?: Types.ObjectId;
  @Prop({ type: [String], required: true }) examenes: string[];
  /** Cifradas a nivel de campo. */
  @Prop({ default: '' }) indicaciones: string;
  @Prop({ required: true }) estado: string;
  @Prop({ type: [Types.ObjectId], default: [] }) examenResultadoIds: Types.ObjectId[];
  @Prop({ required: true }) creadaEn: Date;
  @Prop() completadaEn?: Date;
  /** Cifrado a nivel de campo, igual que las indicaciones. */
  @Prop() motivoAnulacion?: string;
  @Prop() anuladaEn?: Date;
}
export const SolicitudExamenSchema = SchemaFactory.createForClass(SolicitudExamenDoc);
SolicitudExamenSchema.index({ pacienteId: 1, estado: 1 });
