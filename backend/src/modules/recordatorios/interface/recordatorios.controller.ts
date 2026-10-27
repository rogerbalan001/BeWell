import { Body, Controller, Get, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsMongoId, IsOptional } from 'class-validator';
import { Actor, RolUsuario } from '../../../shared/domain/roles';
import { ActorActual, Roles } from '../../../shared/interface/auth/decoradores';
import { RecordatoriosService } from '../application/recordatorios.service';
import { PreferenciasRecordatorio } from '../domain/preferencias-recordatorio';

export class PreferenciasRecordatorioDto {
  @IsOptional() @IsBoolean() citas?: boolean;
  @IsOptional() @IsBoolean() medicamentos?: boolean;
  @IsOptional() @IsBoolean() examenes?: boolean;
}

export class FiltroProximosDto {
  @IsOptional() @IsMongoId() pacienteId?: string;
}

const aRespuesta = (p: PreferenciasRecordatorio) => ({
  citas: p.citas,
  medicamentos: p.medicamentos,
  examenes: p.examenes,
  actualizadoEn: p.actualizadoEn,
});

/** «Boundary» HU-5: recordatorios de citas, medicamentos y exámenes. */
@ApiTags('Recordatorios')
@ApiBearerAuth()
@Roles(RolUsuario.PACIENTE)
@Controller('recordatorios')
export class RecordatoriosController {
  constructor(private readonly recordatorios: RecordatoriosService) {}

  @Get('preferencias')
  async preferencias(@ActorActual() actor: Actor) {
    return aRespuesta(await this.recordatorios.obtenerPreferencias(actor));
  }

  @Put('preferencias')
  async actualizar(@ActorActual() actor: Actor, @Body() dto: PreferenciasRecordatorioDto) {
    return aRespuesta(await this.recordatorios.actualizarPreferencias(actor, dto));
  }

  /** Recordatorios de los próximos 7 días para el titular y sus perfiles (o uno solo con `pacienteId`). */
  @Get('proximos')
  async proximos(@ActorActual() actor: Actor, @Query() q: FiltroProximosDto) {
    return (await this.recordatorios.proximos(actor, q.pacienteId)).map((r) => ({
      tipo: r.tipo,
      pacienteId: r.pacienteId,
      pacienteNombre: r.pacienteNombre,
      programadoPara: r.programadoPara,
      titulo: r.titulo,
      mensaje: r.mensaje,
    }));
  }
}
