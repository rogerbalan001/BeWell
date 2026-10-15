import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { ExpedienteModule } from '../expediente/expediente.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { ExamenesService } from './application/examenes.service';
import { ServicioOcr } from './application/servicio-ocr';
import { ExamenRepository, SolicitudExamenRepository } from './domain/repositorios';
import { ExamenDoc, ExamenSchema, SolicitudExamenDoc, SolicitudExamenSchema } from './infrastructure/examenes.schemas';
import { MongoExamenRepository, MongoSolicitudExamenRepository } from './infrastructure/mongo-examenes.repositories';
import { OcrNoDisponibleAdapter, OcrSimuladoAdapter } from './infrastructure/ocr.adapters';
import { ExamenesController } from './interface/examenes.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ExamenDoc.name, schema: ExamenSchema },
      { name: SolicitudExamenDoc.name, schema: SolicitudExamenSchema },
    ]),
    PerfilesModule,
    MedicosModule,
    ExpedienteModule,
    CitasModule,
  ],
  controllers: [ExamenesController],
  providers: [
    ExamenesService,
    { provide: ExamenRepository, useClass: MongoExamenRepository },
    { provide: SolicitudExamenRepository, useClass: MongoSolicitudExamenRepository },
    {
      provide: ServicioOcr,
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get<string>('OCR_PROVIDER') === 'simulado' ? new OcrSimuladoAdapter() : new OcrNoDisponibleAdapter(),
    },
  ],
})
export class ExamenesModule {}
