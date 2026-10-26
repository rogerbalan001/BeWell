import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { ExpedienteModule } from '../expediente/expediente.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { HistoriaClinicaService } from './application/historia-clinica.service';
import { AntecedentesClinicosRepository, ConsultaClinicaRepository } from './domain/repositorios';
import {
  AntecedentesClinicosDoc,
  AntecedentesClinicosSchema,
  ConsultaClinicaDoc,
  ConsultaClinicaSchema,
} from './infrastructure/historia-clinica.schemas';
import { MongoAntecedentesClinicosRepository, MongoConsultaClinicaRepository } from './infrastructure/mongo-historia-clinica.repositories';
import { HistoriaClinicaController } from './interface/historia-clinica.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AntecedentesClinicosDoc.name, schema: AntecedentesClinicosSchema },
      { name: ConsultaClinicaDoc.name, schema: ConsultaClinicaSchema },
    ]),
    ExpedienteModule,
    CitasModule,
    PerfilesModule,
    MedicosModule,
  ],
  controllers: [HistoriaClinicaController],
  providers: [
    HistoriaClinicaService,
    { provide: AntecedentesClinicosRepository, useClass: MongoAntecedentesClinicosRepository },
    { provide: ConsultaClinicaRepository, useClass: MongoConsultaClinicaRepository },
  ],
  exports: [HistoriaClinicaService],
})
export class HistoriaClinicaModule {}
