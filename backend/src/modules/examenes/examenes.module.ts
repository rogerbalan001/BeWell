import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { ExpedienteModule } from '../expediente/expediente.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { ExamenesService } from './application/examenes.service';
import { ClasificadorExamen } from './application/clasificador-examen';
import { ServicioOcr } from './application/servicio-ocr';
import { ExamenRepository, SolicitudExamenRepository } from './domain/repositorios';
import { ExamenDoc, ExamenSchema, SolicitudExamenDoc, SolicitudExamenSchema } from './infrastructure/examenes.schemas';
import { MongoExamenRepository, MongoSolicitudExamenRepository } from './infrastructure/mongo-examenes.repositories';
import { ClasificadorGeminiAdapter } from './infrastructure/clasificador-gemini.adapter';
import { ClasificadorNoDisponibleAdapter, ClasificadorSimuladoAdapter } from './infrastructure/clasificador-simulado.adapter';
import { OcrNoDisponibleAdapter, OcrSimuladoAdapter } from './infrastructure/ocr.adapters';
import { OcrTesseractAdapter } from './infrastructure/ocr-tesseract.adapter';
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
      // OCR_PROVIDER: "tesseract" (OCR real), "simulado" (plantillas de demo) o vacío (todo queda como adjunto).
      useFactory: (config: ConfigService) => {
        switch (config.get<string>('OCR_PROVIDER')) {
          case 'tesseract':
            return new OcrTesseractAdapter();
          case 'simulado':
            return new OcrSimuladoAdapter();
          default:
            return new OcrNoDisponibleAdapter();
        }
      },
    },
    {
      provide: ClasificadorExamen,
      inject: [ConfigService],
      // IA_EXAMENES: "gemini" (Google Gemini, requiere GEMINI_API_KEY), "simulado" (reglas por analitos y nombre) o "ninguno".
      useFactory: (config: ConfigService): ClasificadorExamen => {
        switch ((config.get<string>('IA_EXAMENES') ?? 'simulado').toLowerCase()) {
          case 'gemini':
            return new ClasificadorGeminiAdapter(config);
          case 'ninguno':
            return new ClasificadorNoDisponibleAdapter();
          default:
            return new ClasificadorSimuladoAdapter();
        }
      },
    },
  ],
})
export class ExamenesModule {}
