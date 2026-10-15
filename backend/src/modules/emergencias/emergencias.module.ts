import { Logger, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import Redis from 'ioredis';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { EmergenciaService } from './application/emergencia.service';
import { FichaEmergenciaCache } from './application/ficha-emergencia.cache';
import { FichaEmergenciaRepository } from './domain/ficha-emergencia';
import { FichaCacheMemoria, FichaCacheRedis } from './infrastructure/ficha-cache.adapters';
import { FichaEmergenciaDoc, FichaEmergenciaSchema } from './infrastructure/ficha-emergencia.schema';
import { MongoFichaEmergenciaRepository } from './infrastructure/mongo-ficha-emergencia.repository';
import { EmergenciaController } from './interface/emergencia.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: FichaEmergenciaDoc.name, schema: FichaEmergenciaSchema }]), PerfilesModule],
  controllers: [EmergenciaController],
  providers: [
    EmergenciaService,
    { provide: FichaEmergenciaRepository, useClass: MongoFichaEmergenciaRepository },
    {
      provide: FichaEmergenciaCache,
      inject: [ConfigService],
      useFactory: (config: ConfigService): FichaEmergenciaCache => {
        const url = config.get<string>('REDIS_URL');
        if (!url) {
          new Logger('Emergencias').warn('REDIS_URL no definido: la caché de fichas QR usa memoria del proceso');
          return new FichaCacheMemoria();
        }
        return new FichaCacheRedis(new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: false }));
      },
    },
  ],
})
export class EmergenciasModule {}
