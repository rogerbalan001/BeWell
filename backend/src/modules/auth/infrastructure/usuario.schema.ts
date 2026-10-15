import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ collection: 'usuarios', versionKey: false })
export class UsuarioDoc {
  _id: Types.ObjectId;
  @Prop({ required: true, unique: true }) email: string;
  @Prop({ required: true }) passwordHash: string;
  @Prop({ type: [String], required: true }) roles: string[];
  @Prop({ required: true }) nombreMostrado: string;
  @Prop() telefono?: string;
  @Prop({ default: false }) mfaHabilitado: boolean;
  @Prop({ default: true }) activo: boolean;
  @Prop({ default: 0 }) versionSesion: number;
  @Prop({ required: true }) creadoEn: Date;
}

export const UsuarioSchema = SchemaFactory.createForClass(UsuarioDoc);
