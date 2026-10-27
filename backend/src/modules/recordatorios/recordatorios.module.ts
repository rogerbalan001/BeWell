import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CitaDoc, CitaSchema } from '../citas/infrastructure/cita.schema';
import { SolicitudExamenDoc, SolicitudExamenSchema } from '../examenes/infrastructure/examenes.schemas';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { RecipeDoc, RecipeSchema } from '../recipes/infrastructure/recipe.schema';
import { FuentesRecordatorio } from './application/fuentes-recordatorio';
import { RecordatoriosService } from './application/recordatorios.service';
import { PreferenciasRecordatorioRepository, RegistroEnviosRepository } from './domain/repositorios';
import { MongoFuentesRecordatorioAdapter } from './infrastructure/mongo-fuentes-recordatorio.adapter';
import { MongoPreferenciasRecordatorioRepository, MongoRegistroEnviosRepository } from './infrastructure/mongo-recordatorios.repositories';
import {
  PreferenciasRecordatorioDoc,
  PreferenciasRecordatorioSchema,
  RecordatorioEnviadoDoc,
  RecordatorioEnviadoSchema,
} from './infrastructure/recordatorios.schemas';
import { RecordatoriosController } from './interface/recordatorios.controller';

/**
 * Recordatorios (HU-5). Sus colecciones propias son las preferencias y el
 * registro de envíos; las de citas, récipes y órdenes solo se leen.
 */
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PreferenciasRecordatorioDoc.name, schema: PreferenciasRecordatorioSchema },
      { name: RecordatorioEnviadoDoc.name, schema: RecordatorioEnviadoSchema },
      { name: CitaDoc.name, schema: CitaSchema },
      { name: RecipeDoc.name, schema: RecipeSchema },
      { name: SolicitudExamenDoc.name, schema: SolicitudExamenSchema },
    ]),
    PerfilesModule,
    MedicosModule,
  ],
  controllers: [RecordatoriosController],
  providers: [
    RecordatoriosService,
    { provide: FuentesRecordatorio, useClass: MongoFuentesRecordatorioAdapter },
    { provide: PreferenciasRecordatorioRepository, useClass: MongoPreferenciasRecordatorioRepository },
    { provide: RegistroEnviosRepository, useClass: MongoRegistroEnviosRepository },
  ],
})
export class RecordatoriosModule {}
