import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { ResenasService } from './application/resenas.service';
import { ResenaRepository } from './domain/resena-verificada';
import { MongoResenaRepository } from './infrastructure/mongo-resena.repository';
import { ResenaDoc, ResenaSchema } from './infrastructure/resena.schema';
import { ResenasController } from './interface/resenas.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: ResenaDoc.name, schema: ResenaSchema }]), CitasModule, PerfilesModule, MedicosModule],
  controllers: [ResenasController],
  providers: [ResenasService, { provide: ResenaRepository, useClass: MongoResenaRepository }],
})
export class ResenasModule {}
