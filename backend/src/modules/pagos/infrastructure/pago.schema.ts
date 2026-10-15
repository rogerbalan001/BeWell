import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ _id: false, versionKey: false })
export class MovimientoPagoDoc {
  @Prop({ required: true }) estado: string;
  @Prop({ required: true }) fecha: Date;
  @Prop() nota?: string;
}

@Schema({ collection: 'pagos', versionKey: false })
export class PagoDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) citaId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) medicoId: Types.ObjectId;
  @Prop({ type: Types.Decimal128, required: true }) monto: Types.Decimal128;
  @Prop({ required: true }) moneda: string;
  @Prop({ required: true }) modalidad: string;
  @Prop({ required: true }) estado: string;
  @Prop() referenciaPasarela?: string;
  @Prop({ required: true, unique: true }) claveIdempotencia: string;
  @Prop() liberarDespuesDe?: Date;
  @Prop({ type: Types.Decimal128, required: true }) montoReembolsado: Types.Decimal128;
  @Prop() motivoDisputa?: string;
  @Prop({ type: [SchemaFactory.createForClass(MovimientoPagoDoc)], default: [] }) historial: MovimientoPagoDoc[];
  @Prop({ required: true }) creadoEn: Date;
  @Prop({ required: true }) actualizadoEn: Date;
}

export const PagoSchema = SchemaFactory.createForClass(PagoDoc);
PagoSchema.index({ estado: 1, liberarDespuesDe: 1 });
