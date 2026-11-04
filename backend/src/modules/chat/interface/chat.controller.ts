import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsDateString, IsOptional, IsString, MaxLength } from 'class-validator';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { ChatService } from '../application/chat.service';
import { LONGITUD_MAXIMA_MENSAJE, MensajeChat } from '../domain/mensaje-chat';

export class EnviarMensajeDto {
  @IsString() @MaxLength(LONGITUD_MAXIMA_MENSAJE) texto: string;
}

export class FiltroMensajesDto {
  /** Solo los mensajes enviados después de esta fecha (la app pide los nuevos cada 5 s). */
  @IsOptional() @IsDateString() despuesDe?: string;
}

const aMensajeRespuesta = (m: MensajeChat) => ({
  id: m.id,
  autor: m.autor,
  texto: m.texto,
  enviadoEn: m.enviadoEn,
  leidoEn: m.leidoEn,
});

/** «Boundary» Chat privado entre el paciente y el médico de una cita. */
@ApiTags('Chat')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE, RolUsuario.MEDICO)
@Controller('chat')
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  /** Mensajes sin leer por cita, para el contador de la app. */
  @Get('no-leidos')
  async noLeidos(@ActorActual() actor: Actor) {
    const porCita = await this.chat.noLeidos(actor);
    return { total: porCita.reduce((s, c) => s + c.noLeidos, 0), porCita };
  }

  @Get('citas/:citaId/mensajes')
  async mensajes(@ActorActual() actor: Actor, @Param('citaId', ParseObjectIdPipe) citaId: string, @Query() q: FiltroMensajesDto) {
    const c = await this.chat.conversacion(actor, citaId, q.despuesDe ? new Date(q.despuesDe) : undefined);
    return { citaId: c.cita.id, miParte: c.miParte, habilitado: c.habilitado, mensajes: c.mensajes.map(aMensajeRespuesta) };
  }

  @Post('citas/:citaId/mensajes')
  async enviar(@ActorActual() actor: Actor, @Param('citaId', ParseObjectIdPipe) citaId: string, @Body() dto: EnviarMensajeDto) {
    return aMensajeRespuesta(await this.chat.enviar(actor, citaId, dto.texto));
  }

  @HttpCode(200)
  @Post('citas/:citaId/leidos')
  async leidos(@ActorActual() actor: Actor, @Param('citaId', ParseObjectIdPipe) citaId: string) {
    return { marcados: await this.chat.marcarLeidos(actor, citaId) };
  }
}
