import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Types } from 'mongoose';

@Schema({ _id: false, versionKey: false })
export class ContactoEmergenciaDoc {
  @Prop({ required: true }) nombre: string;
  @Prop({ default: '' }) parentesco: string;
  @Prop({ required: true }) telefono: string;
}

@Schema({ collection: 'fichas_emergencia', versionKey: false })
export class FichaEmergenciaDoc {
  _id: Types.ObjectId;
  @Prop({ type: Types.ObjectId, required: true, unique: true }) pacienteId: Types.ObjectId;
  @Prop({ unique: true, sparse: true }) tokenQrHash?: string;
  @Prop() qrGeneradoEn?: Date;
  @Prop() grupoSanguineo?: string;
  @Prop({ type: [String], default: [] }) alergias: string[];
  /** Cifrados a nivel de campo. */
  @Prop({ type: [String], default: [] }) condicionesCronicas: string[];
  @Prop({ type: [String], default: [] }) medicacionActual: string[];
  @Prop({ type: [SchemaFactory.createForClass(ContactoEmergenciaDoc)], default: [] }) contactos: ContactoEmergenciaDoc[];
  @Prop({ type: [String], default: [] }) camposPublicos: string[];
  @Prop({ required: true }) actualizadoEn: Date;
}

export const FichaEmergenciaSchema = SchemaFactory.createForClass(FichaEmergenciaDoc);
