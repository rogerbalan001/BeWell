import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AgendaService } from './application/agenda.service';
import { MedicosService } from './application/medicos.service';
import { VerificacionProfesionalService } from './application/verificacion-profesional.service';
import { MedicoRepository } from './domain/medico.repository';
import { MedicoDoc, MedicoSchema } from './infrastructure/medico.schema';
import { MongoMedicoRepository } from './infrastructure/mongo-medico.repository';
import { AgendaController } from './interface/agenda.controller';
import { MedicosController } from './interface/medicos.controller';
import { VerificacionController } from './interface/verificacion.controller';

/** Médicos: directorio, verificación profesional y agenda (dueño de la colección `medicos`). */
@Module({
  imports: [MongooseModule.forFeature([{ name: MedicoDoc.name, schema: MedicoSchema }])],
  controllers: [MedicosController, VerificacionController, AgendaController],
  providers: [
    MedicosService,
    VerificacionProfesionalService,
    AgendaService,
    { provide: MedicoRepository, useClass: MongoMedicoRepository },
  ],
  exports: [MedicosService],
})
export class MedicosModule {}
