import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'pacientes', versionKey: false })
export class PerfilPacienteDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, index: true }) titularUsuarioId: Types.ObjectId;
  @Prop({ required: true }) parentescoConTitular: string;
  @Prop({ required: true }) nombres: string;
  @Prop({ required: true }) apellidos: string;
  /** Cédula cifrada a nivel de campo. */
  @Prop() cedulaCifrada?: string;
  /** HMAC de la cédula: permite búsqueda por igualdad sin exponerla. */
  @Prop({ index: true, sparse: true }) cedulaHuella?: string;
  @Prop({ required: true }) fechaNacimiento: Date;
  @Prop({ required: true }) sexo: string;
  @Prop({ required: true }) creadoEn: Date;
}

export const PerfilPacienteSchema = SchemaFactory.createForClass(PerfilPacienteDoc);
