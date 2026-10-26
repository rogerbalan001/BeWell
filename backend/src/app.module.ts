import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_FILTER, APP_GUARD } from '@nestjs/core';
import { MongooseModule } from '@nestjs/mongoose';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { SaludController } from './salud.controller';
import { AuditoriaModule } from './modules/auditoria/auditoria.module';
import { AuthModule } from './modules/auth/auth.module';
import { CitasModule } from './modules/citas/citas.module';
import { DemoModule } from './modules/demo/demo.module';
import { EmergenciasModule } from './modules/emergencias/emergencias.module';
import { ExamenesModule } from './modules/examenes/examenes.module';
import { ExpedienteModule } from './modules/expediente/expediente.module';
import { HistoriaClinicaModule } from './modules/historia-clinica/historia-clinica.module';
import { MedicosModule } from './modules/medicos/medicos.module';
import { NotificacionesModule } from './modules/notificaciones/notificaciones.module';
import { PagosModule } from './modules/pagos/pagos.module';
import { PerfilesModule } from './modules/perfiles/perfiles.module';
import { RecipesModule } from './modules/recipes/recipes.module';
import { ResenasModule } from './modules/resenas/resenas.module';
import { ErroresDominioFilter } from './shared/interface/http/errores-dominio.filter';
import { SharedModule } from './shared/shared.module';

/**
 * Monolito modular: cada módulo es un bounded context dueño de sus
 * colecciones y se comunica con los demás solo a través de sus servicios
 * públicos (exports) o de los puertos globales (Notificador, RegistroAuditoria).
 */
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({ uri: config.getOrThrow<string>('MONGO_URI'), autoIndex: true }),
    }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 300 }]),
    ScheduleModule.forRoot(),
    SharedModule,
    AuditoriaModule,
    NotificacionesModule,
    AuthModule,
    PerfilesModule,
    MedicosModule,
    PagosModule,
    ExpedienteModule,
    CitasModule,
    HistoriaClinicaModule,
    ResenasModule,
    ExamenesModule,
    RecipesModule,
    EmergenciasModule,
    DemoModule,
  ],
  controllers: [SaludController],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_FILTER, useClass: ErroresDominioFilter },
  ],
})
export class AppModule {}
