import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'expedientes', versionKey: false })
export class ExpedienteDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) pacienteId: Types.ObjectId;
  /** Cifrados a nivel de campo. */
  @Prop({ type: [String], default: [] }) antecedentes: string[];
  @Prop({ required: true }) actualizadoEn: Date;
}
export const ExpedienteSchema = SchemaFactory.createForClass(ExpedienteDoc);

@Schema({ collection: 'permisos_acceso', versionKey: false })
export class PermisoAccesoDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) expedienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) medicoId: Types.ObjectId;
  @Prop({ type: [String], required: true }) categoriasPermitidas: string[];
  @Prop({ default: false }) escritura: boolean;
  @Prop({ required: true }) validoHasta: Date;
  @Prop({ default: false }) revocado: boolean;
  @Prop() revocadoEn?: Date;
  @Prop({ type: Types.ObjectId, required: true }) otorgadoPorUsuarioId: Types.ObjectId;
  @Prop({ required: true }) origen: string;
  @Prop({ required: true }) creadoEn: Date;
}
export const PermisoAccesoSchema = SchemaFactory.createForClass(PermisoAccesoDoc);
PermisoAccesoSchema.index({ pacienteId: 1, medicoId: 1, validoHasta: 1 });
PermisoAccesoSchema.index({ medicoId: 1, revocado: 1, validoHasta: 1 });

@Schema({ collection: 'eventos_clinicos', versionKey: false })
export class EventoClinicoDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) expedienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) pacienteId: Types.ObjectId;
  @Prop({ required: true }) tipo: string;
  @Prop({ required: true }) categoria: string;
  @Prop({ required: true }) fecha: Date;
  @Prop({ required: true }) titulo: string;
  /** Cifrado a nivel de campo. */
  @Prop({ default: '' }) resumen: string;
  @Prop({ type: Types.ObjectId }) medicoId?: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) autorUsuarioId?: Types.ObjectId;
  @Prop({ type: Types.ObjectId }) documentoOrigenId?: Types.ObjectId;
  @Prop({ type: Object, default: {} }) detalles: Record<string, string>;
  @Prop({ required: true }) creadoEn: Date;
}
export const EventoClinicoSchema = SchemaFactory.createForClass(EventoClinicoDoc);
EventoClinicoSchema.index({ pacienteId: 1, fecha: -1 });
EventoClinicoSchema.index({ pacienteId: 1, categoria: 1, fecha: -1 });

@Schema({ collection: 'referencias', versionKey: false })
export class ReferenciaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) pacienteId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true }) medicoOrigenId: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) medicoDestinoId: Types.ObjectId;
  @Prop({ required: true }) especialidadDestino: string;
  /** Cifrado a nivel de campo. */
  @Prop({ required: true }) motivo: string;
  @Prop({ required: true }) estado: string;
  @Prop({ required: true }) fecha: Date;
  @Prop() respondidaEn?: Date;
}
export const ReferenciaSchema = SchemaFactory.createForClass(ReferenciaDoc);
