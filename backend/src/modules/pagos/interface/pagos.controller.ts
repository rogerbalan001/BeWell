import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { aMonto } from '../../../shared/domain/dinero';
import { RolUsuario } from '../../../shared/domain/roles';
import { Roles } from '../../../shared/interface/auth/decoradores';
import { ParseObjectIdPipe } from '../../../shared/interface/http/parse-object-id.pipe';
import { PagosService } from '../application/pagos.service';
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
  montoReembolsado: aMonto(p.montoReembolsado),
  liberarDespuesDe: p.liberarDespuesDe,
  motivoDisputa: p.motivoDisputa,
  referenciaPasarela: p.referenciaPasarela,
  historial: p.historial,
});

/** «Boundary» Gestión de disputas de pago (administrador). */
@ApiTags('Pagos')
@ApiBearerAuth()
@Roles(RolUsuario.ADMIN)
@Controller('pagos')
export class PagosController {
  constructor(private readonly pagos: PagosService) {}

  @Get('disputas')
  async disputas() {
    return (await this.pagos.listarDisputas()).map(aPagoRespuesta);
  }

  @Post(':id/resolver')
  async resolver(@Param('id', ParseObjectIdPipe) id: string, @Body() dto: ResolverDisputaDto) {
    return aPagoRespuesta(await this.pagos.resolverDisputa(id, dto.accion, dto.nota ?? ''));
  }
}
