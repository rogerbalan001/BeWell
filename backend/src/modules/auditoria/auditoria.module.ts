import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { RegistroAuditoria } from '../../shared/application/registro-auditoria';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { AuditoriaService } from './application/auditoria.service';
import { AuditoriaRepository } from './domain/registro-auditoria';
import { RegistroAuditoriaDoc, RegistroAuditoriaSchema } from './infrastructure/auditoria.schema';
import { MongoAuditoriaRepository } from './infrastructure/mongo-auditoria.repository';
import { AuditoriaController } from './interface/auditoria.controller';

/** Auditoría de accesos (global: cualquier módulo inyecta el puerto RegistroAuditoria). */
@Global()
@Module({
  imports: [MongooseModule.forFeature([{ name: RegistroAuditoriaDoc.name, schema: RegistroAuditoriaSchema }]), PerfilesModule],
  controllers: [AuditoriaController],
  providers: [
    AuditoriaService,
    { provide: AuditoriaRepository, useClass: MongoAuditoriaRepository },
    { provide: RegistroAuditoria, useExisting: AuditoriaService },
  ],
  exports: [RegistroAuditoria],
})
export class AuditoriaModule {}
