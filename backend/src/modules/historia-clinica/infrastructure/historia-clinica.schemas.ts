import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'antecedentes_clinicos', versionKey: false })
export class AntecedentesClinicosDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) pacienteId: Types.ObjectId;
  /** JSON de DatosAntecedentes cifrado a nivel de campo (D9). */
  @Prop({ required: true }) datos: string;
  @Prop({ required: true }) actualizadoEn: Date;
  @Prop({ type: Types.ObjectId }) actualizadoPorUsuarioId?: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) actualizadoPorMedicoId?: Types.ObjectId;
}
export const AntecedentesClinicosSchema = SchemaFactory.createForClass(AntecedentesClinicosDoc);

@Schema({ collection: 'consultas_clinicas', versionKey: false })
export class ConsultaClinicaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) autorUsuarioId: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) citaId?: Types.ObjectId;
  @Prop({ required: true }) fecha: Date;
  /** JSON de ContenidoConsulta cifrado a nivel de campo (D9). */
  @Prop({ required: true }) contenido: string;
  @Prop({ required: true }) creadaEn: Date;
  @Prop({ required: true }) actualizadaEn: Date;
}
export const ConsultaClinicaSchema = SchemaFactory.createForClass(ConsultaClinicaDoc);
ConsultaClinicaSchema.index({ pacienteId: 1, fecha: -1 });
/** Una historia por cita. */
ConsultaClinicaSchema.index({ citaId: 1 }, { unique: true, partialFilterExpression: { citaId: { $exists: true } } });
