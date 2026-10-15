import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Notificador } from '../../shared/application/notificador';
import { NotificacionesService } from './application/notificaciones.service';
import { NotificacionRepository } from './domain/notificacion';
import { MongoNotificacionRepository } from './infrastructure/mongo-notificacion.repository';
import { NotificacionDoc, NotificacionSchema } from './infrastructure/notificacion.schema';
import { NotificacionesController } from './interface/notificaciones.controller';

/** Notificaciones (global: cualquier módulo inyecta el puerto Notificador). */
@Global()
@Module({
  imports: [MongooseModule.forFeature([{ name: NotificacionDoc.name, schema: NotificacionSchema }])],
  controllers: [NotificacionesController],
  providers: [
    NotificacionesService,
    { provide: NotificacionRepository, useClass: MongoNotificacionRepository },
    { provide: Notificador, useExisting: NotificacionesService },
  ],
  exports: [Notificador],
})
export class NotificacionesModule {}
