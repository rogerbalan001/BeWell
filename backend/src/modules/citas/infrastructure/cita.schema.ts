import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';
import { PoliticaCancelacionDoc, PoliticaCancelacionSchema } from '../../medicos/infrastructure/medico.schema';

@Schema({ collection: 'citas', versionKey: false })
export class CitaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) agendadaPorUsuarioId: Types.ObjectId;
  @Prop({ required: true }) inicio: Date;
  @Prop({ required: true }) fin: Date;
  @Prop({ required: true }) modalidad: string;
  @Prop({ default: '' }) motivo: string;
  @Prop({ required: true }) estado: string;
  /** true mientras la cita ocupa la franja (pendiente o confirmada). */
  @Prop({ required: true }) ocupaFranja: boolean;
  @Prop({ type: Types.Decimal128, required: true }) monto: Types.Decimal128;
  @Prop({ required: true }) moneda: string;
  @Prop({ type: PoliticaCancelacionSchema, required: true }) politicaAplicada: PoliticaCancelacionDoc;
  @Prop({ type: Types.ObjectId }) citaOrigenId?: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) referenciaId?: Types.ObjectId;
  @Prop() propuestaPor?: string;
  @Prop() propuestaExpiraEn?: Date;
  @Prop() canceladaPor?: string;
  @Prop() motivoCancelacion?: string;
  @Prop() canceladaEn?: Date;
  @Prop() atendidaEn?: Date;
  @Prop({ required: true }) creadaEn: Date;
}

export const CitaSchema = SchemaFactory.createForClass(CitaDoc);
// Impide la doble reserva: (medicoId, inicio) único solo para citas activas.
CitaSchema.index({ medicoId: 1, inicio: 1 }, { unique: true, partialFilterExpression: { ocupaFranja: true } });
CitaSchema.index({ pacienteId: 1, inicio: -1 });
CitaSchema.index({ estado: 1, propuestaExpiraEn: 1 });
