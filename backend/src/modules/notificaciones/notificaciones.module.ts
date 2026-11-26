import { Global, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Notificador } from '../../shared/application/notificador';
import { NotificacionesService } from './application/notificaciones.service';
import { PushService } from './application/push.service';
import { PushRepository } from './domain/push';
import { NotificacionRepository } from './domain/notificacion';
import { MongoNotificacionRepository } from './infrastructure/mongo-notificacion.repository';
import { MongoPushRepository } from './infrastructure/mongo-push.repository';
import { ConfiguracionPushDoc, ConfiguracionPushSchema, SuscripcionPushDoc, SuscripcionPushSchema } from './infrastructure/push.schemas';
import { NotificacionDoc, NotificacionSchema } from './infrastructure/notificacion.schema';
import { NotificacionesController } from './interface/notificaciones.controller';

/** Notificaciones (global: cualquier módulo inyecta el puerto Notificador). */
@Global()
@Module({
  imports: [
    MongooseModule.forFeature([
      { name: NotificacionDoc.name, schema: NotificacionSchema },
      { name: SuscripcionPushDoc.name, schema: SuscripcionPushSchema },
      { name: ConfiguracionPushDoc.name, schema: ConfiguracionPushSchema },
    ]),
  ],
  controllers: [NotificacionesController],
  providers: [
    NotificacionesService,
    PushService,
    { provide: NotificacionRepository, useClass: MongoNotificacionRepository },
    { provide: PushRepository, useClass: MongoPushRepository },
    { provide: Notificador, useExisting: NotificacionesService },
  ],
  exports: [Notificador],
})
export class NotificacionesModule {}
