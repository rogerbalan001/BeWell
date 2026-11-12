import { Controller, Get, Logger, Query, Res } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiExcludeController } from '@nestjs/swagger';
import type { Response } from 'express';
import { EstadoCita } from '../domain/cita';
import { Publico } from '../../../shared/interface/auth/decoradores';
import { CitasService } from '../application/citas.service';

/**
 * «Boundary» Retorno desde PayPal. PayPal redirige aquí al paciente (con
 * `?token=<orden>`) después de aprobar o cancelar el pago. Es público porque
 * llega desde el navegador sin el token de sesión; la orden identifica el pago
 * y solo puede autorizarse si el paciente la aprobó en PayPal.
 * Al terminar redirige a la cita en la app web.
 */
@ApiExcludeController()
@Controller('pagos/paypal')
export class PagoPayPalController {
  private readonly logger = new Logger(PagoPayPalController.name);

  constructor(
    private readonly citas: CitasService,
    private readonly config: ConfigService,
  ) {}

  @Publico()
  @Get('retorno')
  async retorno(@Query('token') orden: string | undefined, @Res() res: Response): Promise<void> {
    if (!orden) return res.redirect(302, this.urlWeb('/citas', 'error'));
    try {
      const { cita } = await this.citas.completarPagoPorOrden(orden);
      const resultado = cita.estado === EstadoCita.CONFIRMADA ? 'ok' : cita.estado === EstadoCita.PENDIENTE_PAGO ? 'pendiente' : 'rechazado';
      res.redirect(302, this.urlWeb(`/citas/${cita.id}`, resultado));
    } catch (e) {
      this.logger.error(`Retorno de PayPal (orden ${orden}): ${(e as Error).message}`);
      res.redirect(302, this.urlWeb('/citas', 'error'));
    }
  }

  /** El paciente tocó "Cancelar y volver" en PayPal: la cita sigue pendiente para que reintente o la cancele. */
  @Publico()
  @Get('cancelado')
  async cancelado(@Query('token') orden: string | undefined, @Res() res: Response): Promise<void> {
    const citaId = orden ? await this.citas.citaDeOrden(orden).catch(() => null) : null;
    res.redirect(302, this.urlWeb(citaId ? `/citas/${citaId}` : '/citas', 'cancelado'));
  }

  private urlWeb(ruta: string, pago: string): string {
    const base = (this.config.get<string>('PUBLIC_WEB_URL') ?? 'http://localhost:8080/#').replace(/\/$/, '');
    return `${base}${ruta}?pago=${pago}`;
  }
}
