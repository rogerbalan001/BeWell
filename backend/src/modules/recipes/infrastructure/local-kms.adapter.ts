import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { createCipheriv, createDecipheriv, generateKeyPairSync, randomBytes, sign } from 'crypto';
import { Model } from 'mongoose';
import { NoEncontradoError } from '../../../shared/domain/errores';
import { llaveDe32Bytes } from '../../../shared/infrastructure/cifrado/llaves';
import { generarId } from '../../../shared/domain/id';
import { Kms } from '../application/kms';

@Schema({ collection: 'llaves_firma', versionKey: false })
export class LlaveFirmaDoc {
  @Prop({ required: true }) _id: string;
  /** Llave privada PKCS#8 envuelta con la llave maestra (AES-256-GCM). */
  @Prop({ required: true }) privadaEnvuelta: string;
  @Prop({ required: true }) publicaPem: string;
  @Prop({ required: true }) algoritmo: string;
  @Prop({ required: true }) creadaEn: Date;
}
export const LlaveFirmaSchema = SchemaFactory.createForClass(LlaveFirmaDoc);

/**
 * KMS local para el MVP: genera llaves ECDSA P-256 por médico y guarda la
 * privada envuelta con KMS_MASTER_KEY. Expone solo firmar() y la llave
 * pública, igual que AWS KMS / Cloud KMS, por lo que puede reemplazarse sin
 * tocar el dominio.
 */
@Injectable()
export class LocalKmsAdapter extends Kms {
  private readonly maestra: Buffer;

  constructor(
    @InjectModel(LlaveFirmaDoc.name) private readonly modelo: Model<LlaveFirmaDoc>,
    config: ConfigService,
  ) {
    super();
    this.maestra = llaveDe32Bytes(config.get<string>('KMS_MASTER_KEY'), 'KMS_MASTER_KEY');
  }

  async crearLlaveFirma(): Promise<string> {
    const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
    const id = `llave-${generarId()}`;
    await this.modelo.create({
      _id: id,
      privadaEnvuelta: this.envolver(privateKey.export({ type: 'pkcs8', format: 'pem' }).toString()),
      publicaPem: publicKey.export({ type: 'spki', format: 'pem' }).toString(),
      algoritmo: 'ECDSA_P256_SHA256',
      creadaEn: new Date(),
    });
    return id;
  }

  async firmar(llaveId: string, contenido: Buffer): Promise<string> {
    const llave = await this.obtener(llaveId);
    return sign('sha256', contenido, this.desenvolver(llave.privadaEnvuelta)).toString('base64');
  }

  async obtenerLlavePublica(llaveId: string): Promise<string> {
    return (await this.obtener(llaveId)).publicaPem;
  }

  private async obtener(llaveId: string): Promise<LlaveFirmaDoc> {
    const llave = await this.modelo.findById(llaveId).lean();
    if (!llave) throw new NoEncontradoError('Llave de firma', llaveId);
    return llave;
  }

  private envolver(pem: string): string {
    const iv = randomBytes(12);
    const c = createCipheriv('aes-256-gcm', this.maestra, iv);
    const cifrado = Buffer.concat([c.update(pem, 'utf8'), c.final()]);
    return Buffer.concat([iv, c.getAuthTag(), cifrado]).toString('base64');
  }

  private desenvolver(envuelta: string): string {
    const d = Buffer.from(envuelta, 'base64');
    const decipher = createDecipheriv('aes-256-gcm', this.maestra, d.subarray(0, 12));
    decipher.setAuthTag(d.subarray(12, 28));
    return Buffer.concat([decipher.update(d.subarray(28)), decipher.final()]).toString('utf8');
  }
}
