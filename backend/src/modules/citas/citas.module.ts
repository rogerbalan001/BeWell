import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ExpedienteModule } from '../expediente/expediente.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PagosModule } from '../pagos/pagos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { CitasService } from './application/citas.service';
import { CitaRepository } from './domain/cita.repository';
import { CitaDoc, CitaSchema } from './infrastructure/cita.schema';
import { MongoCitaRepository } from './infrastructure/mongo-cita.repository';
import { CitasController } from './interface/citas.controller';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: CitaDoc.name, schema: CitaSchema }]),
    PerfilesModule,
    MedicosModule,
    PagosModule,
    ExpedienteModule,
  ],
  controllers: [CitasController],
  providers: [CitasService, { provide: CitaRepository, useClass: MongoCitaRepository }],
  exports: [CitasService],
})
export class CitasModule {}
