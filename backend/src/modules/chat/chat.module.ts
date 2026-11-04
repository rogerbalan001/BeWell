import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CitasModule } from '../citas/citas.module';
import { MedicosModule } from '../medicos/medicos.module';
import { PerfilesModule } from '../perfiles/perfiles.module';
import { ChatService } from './application/chat.service';
import { MensajeChatRepository } from './domain/mensaje-chat.repository';
import { MensajeChatDoc, MensajeChatSchema } from './infrastructure/mensaje-chat.schema';
import { MongoMensajeChatRepository } from './infrastructure/mongo-mensaje-chat.repository';
import { ChatController } from './interface/chat.controller';

/** Chat médico-paciente por cita (Sprint 3). */
@Module({
  imports: [MongooseModule.forFeature([{ name: MensajeChatDoc.name, schema: MensajeChatSchema }]), CitasModule, PerfilesModule, MedicosModule],
  controllers: [ChatController],
  providers: [ChatService, { provide: MensajeChatRepository, useClass: MongoMensajeChatRepository }],
})
export class ChatModule {}
