import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AlmacenamientoArchivos } from './application/almacenamiento-archivos';
import { CifradorCampos } from './application/cifrador-campos';
import { GeneradorPdf } from './application/generador-pdf';
import { Reloj, RelojSistema } from './domain/reloj';
import { AlmacenamientoLocal } from './infrastructure/almacenamiento/almacenamiento-local';
import { AesGcmCifradorCampos } from './infrastructure/cifrado/aes-gcm-cifrador-campos';
import { GeneradorPdfTexto } from './infrastructure/pdf/generador-pdf-texto';
import { llaveDe32Bytes } from './infrastructure/cifrado/llaves';
import { ArchivosController } from './interface/http/archivos.controller';

const llave = (config: ConfigService, nombre: string): Buffer => llaveDe32Bytes(config.get<string>(nombre), nombre);

/** Módulo transversal: reloj, cifrado de campos, almacenamiento de objetos y PDF. */
@Global()
@Module({
  controllers: [ArchivosController],
  providers: [
    { provide: Reloj, useClass: RelojSistema },
    { provide: GeneradorPdf, useClass: GeneradorPdfTexto },
    {
      provide: CifradorCampos,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => new AesGcmCifradorCampos(llave(config, 'FIELD_ENCRYPTION_KEY')),
    },
    {
      provide: AlmacenamientoArchivos,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        new AlmacenamientoLocal(
          config.get<string>('STORAGE_DIR') ?? './storage',
          llave(config, 'FIELD_ENCRYPTION_KEY'),
          config.getOrThrow<string>('URL_SIGNING_SECRET'),
          config.get<string>('PUBLIC_API_URL') ?? 'http://localhost:3000/api/v1',
        ),
    },
  ],
  exports: [Reloj, CifradorCampos, AlmacenamientoArchivos, GeneradorPdf],
})
export class SharedModule {}
