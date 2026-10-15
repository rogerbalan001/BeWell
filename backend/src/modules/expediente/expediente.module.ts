import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { ExpedienteService } from './application/expediente.service';
import { PoliticaAccesoExpediente } from './application/politica-acceso-expediente';
import { ReferenciasService } from './application/referencias.service';
import {
  EventoClinicoRepository,
  ExpedienteRepository,
  PermisoAccesoRepository,
  ReferenciaRepository,
} from './domain/repositorios';
import {
  EventoClinicoDoc,
  EventoClinicoSchema,
  ExpedienteDoc,
  ExpedienteSchema,
  PermisoAccesoDoc,
  PermisoAccesoSchema,
  ReferenciaDoc,
  ReferenciaSchema,
} from './infrastructure/expediente.schemas';
import {
  MongoEventoClinicoRepository,
  MongoExpedienteRepository,
  MongoPermisoAccesoRepository,
  MongoReferenciaRepository,
} from './infrastructure/mongo-expediente.repositories';
import { ExpedienteController } from './interface/expediente.controller';
import { ReferenciasController } from './interface/referencias.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ExpedienteDoc.name, schema: ExpedienteSchema },
      { name: PermisoAccesoDoc.name, schema: PermisoAccesoSchema },
      { name: EventoClinicoDoc.name, schema: EventoClinicoSchema },
      { name: ReferenciaDoc.name, schema: ReferenciaSchema },
    ]),
    PerfilesModule,
    MedicosModule,
  ],
  controllers: [ExpedienteController, ReferenciasController],
  providers: [
    ExpedienteService,
    PoliticaAccesoExpediente,
    ReferenciasService,
    { provide: ExpedienteRepository, useClass: MongoExpedienteRepository },
    { provide: PermisoAccesoRepository, useClass: MongoPermisoAccesoRepository },
    { provide: EventoClinicoRepository, useClass: MongoEventoClinicoRepository },
    { provide: ReferenciaRepository, useClass: MongoReferenciaRepository },
  ],
  exports: [ExpedienteService, PoliticaAccesoExpediente, ReferenciasService],
})
export class ExpedienteModule {}
