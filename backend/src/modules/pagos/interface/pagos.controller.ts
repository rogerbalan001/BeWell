import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { aMonto } from '../../../shared/domain/dinero';
import { RolUsuario } from '../../../shared/domain/roles';
import { Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { DisputaConPartes, DisputasService } from '../application/disputas.service';
import { Pago } from '../domain/pago';

export class ResolverDisputaDto {
  @IsIn(['LIBERAR', 'REEMBOLSAR']) accion: 'LIBERAR' | 'REEMBOLSAR';
  @IsOptional() @IsString() @MaxLength(300) nota?: string;
}

export const aPagoRespuesta = (p: Pago) => ({
  id: p.id,
  citaId: p.citaId,
  monto: aMonto(p.monto),
  moneda: p.moneda,
  estado: p.estado,
  proveedor: p.proveedor,
  /** Página de PayPal donde el paciente aprueba el pago (solo mientras está pendiente). */
  urlAprobacion: p.pendienteDeAprobacion ? p.urlAprobacion : undefined,
  montoReembolsado: aMonto(p.montoReembolsado),
  liberarDespuesDe: p.liberarDespuesDe,
  motivoDisputa: p.motivoDisputa,
  referenciaPasarela: p.referenciaPasarela,
  historial: p.historial,
});

const aDisputaRespuesta = ({ pago, partes }: DisputaConPartes) => ({
  ...aPagoRespuesta(pago),
  pacienteNombre: partes.pacienteNombre,
  medicoNombre: partes.medicoNombre,
  /** Fecha en que el paciente reportó el problema. */
  abiertaEn: [...pago.historial].reverse().find((h) => h.estado === 'EN_DISPUTA')?.fecha,
});

/** «Boundary» Gestión de disputas de pago (administrador). */
@ApiTags('Pagos')
@ApiBearerAuth()
@Roles(RolUsuario.ADMIN)
@Controller('pagos')
export class PagosController {
  constructor(private readonly servicio: DisputasService) {}

  @Get('disputas')
  async disputas() {
    return (await this.servicio.listar()).map(aDisputaRespuesta);
  }

  @Post(':id/resolver')
  async resolver(@Param('id', ParseObjectIdPipe) id: string, @Body() dto: ResolverDisputaDto) {
    return aDisputaRespuesta(await this.servicio.resolver(id, dto.accion, dto.nota ?? ''));
  }
}
