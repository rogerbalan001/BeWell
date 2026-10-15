import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PerfilesService } from './application/perfiles.service';
import { PerfilPacienteRepository } from './domain/perfil-paciente.repository';
import { MongoPerfilPacienteRepository } from './infrastructure/mongo-perfil-paciente.repository';
import { PerfilPacienteDoc, PerfilPacienteSchema } from './infrastructure/perfil-paciente.schema';
import { PerfilesController } from './interface/perfiles.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: PerfilPacienteDoc.name, schema: PerfilPacienteSchema }])],
  controllers: [PerfilesController],
  providers: [PerfilesService, { provide: PerfilPacienteRepository, useClass: MongoPerfilPacienteRepository }],
  exports: [PerfilesService],
})
export class PerfilesModule {}
