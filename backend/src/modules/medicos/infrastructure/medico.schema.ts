import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ _id: false, versionKey: false })
export class CredencialDoc {
  @Prop({ required: true }) id: string;
  @Prop({ required: true }) tipo: string;
  @Prop({ required: true }) numero: string;
  @Prop({ required: true }) archivoRef: string;
  @Prop({ required: true }) estado: string;
  @Prop({ required: true }) enviadaEn: Date;
  @Prop({ type: Types.ObjectId }) revisadoPorId?: Types.ObjectId;
  @Prop() fechaRevision?: Date;
  @Prop() observaciones?: string;
}

@Schema({ _id: false, versionKey: false })
export class PoliticaCancelacionDoc {
  @Prop({ required: true }) tipo: string;
  @Prop({ required: true }) horasMinimasAviso: number;
  @Prop({ required: true }) porcentajePenalizacion: number;
}
export const PoliticaCancelacionSchema = SchemaFactory.createForClass(PoliticaCancelacionDoc);

@Schema({ _id: false, versionKey: false })
export class BloqueHorarioDoc {
  @Prop({ required: true }) diaSemana: number;
  @Prop({ required: true }) horaInicio: string;
  @Prop({ required: true }) horaFin: string;
  @Prop({ required: true }) duracionCitaMin: number;
}

@Schema({ collection: 'medicos', versionKey: false })
export class MedicoDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) usuarioId: Types.ObjectId;
  @Prop({ required: true }) nombres: string;
  @Prop({ required: true }) apellidos: string;
  @Prop({ type: [String], required: true }) especialidades: string[];
  @Prop({ type: Types.Decimal128, required: true }) tarifaConsulta: Types.Decimal128;
  @Prop({ required: true }) moneda: string;
  @Prop({ required: true }) estadoVerificacion: string;
  @Prop({ type: [SchemaFactory.createForClass(CredencialDoc)], default: [] }) credenciales: CredencialDoc[];
  @Prop({ type: PoliticaCancelacionSchema, required: true }) politicaCancelacion: PoliticaCancelacionDoc;
  @Prop({ type: [SchemaFactory.createForClass(BloqueHorarioDoc)], default: [] }) horario: BloqueHorarioDoc[];
  @Prop({ type: [String], default: [] }) modalidades: string[];
  @Prop() direccionConsultorio?: string;
  @Prop() biografia?: string;
  @Prop({ required: true }) zonaHorariaMin: number;
  @Prop({ default: 0 }) calificacionPromedio: number;
  @Prop({ default: 0 }) totalResenas: number;
  @Prop() llaveFirmaId?: string;
  @Prop({ required: true }) creadoEn: Date;
}

export const MedicoSchema = SchemaFactory.createForClass(MedicoDoc);
// Búsquedas del directorio: especialidad + estado de verificación.
MedicoSchema.index({ especialidades: 1, estadoVerificacion: 1 });
MedicoSchema.index({ 'credenciales.estado': 1 });
