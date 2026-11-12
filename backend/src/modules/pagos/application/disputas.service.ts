import { Injectable } from '@nestjs/common';
import { Notificador } from '../../../shared/application/notificador';
import { Pago } from '../domain/pago';
import { PagosService } from './pagos.service';
import { ParticipantesPago, ParticipantesPagoPuerto } from './participantes-pago';

/** Disputa abierta, con las partes ya resueltas para la pantalla del administrador. */
export interface DisputaConPartes {
  pago: Pago;
  partes: ParticipantesPago;
}

export type AccionDisputa = 'LIBERAR' | 'REEMBOLSAR';

/**
 * «Control» DisputasService. El administrador revisa los pagos retenidos por
 * un reporte del paciente y decide: liberar el dinero al médico o
 * reembolsarlo al paciente. Ambas partes reciben un aviso con la decisión.
 */
@Injectable()
export class DisputasService {
  constructor(
    private readonly pagos: PagosService,
    private readonly participantes: ParticipantesPagoPuerto,
    private readonly notificador: Notificador,
  ) {}

  /** Disputas abiertas, de la más antigua a la más reciente. */
  async listar(): Promise<DisputaConPartes[]> {
    const pagos = await this.pagos.listarDisputas();
    return Promise.all(pagos.map(async (pago) => ({ pago, partes: await this.participantes.de(pago) })));
  }

  /** Resuelve la disputa en la pasarela y avisa al paciente y al médico. */
  async resolver(pagoId: string, accion: AccionDisputa, nota: string): Promise<DisputaConPartes> {
    const pago = await this.pagos.resolverDisputa(pagoId, accion, nota);
    const partes = await this.participantes.de(pago);
    const detalle = nota.trim() ? ` Nota del equipo de Bewell: ${nota.trim()}` : '';
    if (accion === 'REEMBOLSAR') {
      await this.avisar(partes.pacienteUsuarioId, pago, 'Reporte resuelto: reembolso aprobado', `Revisamos tu reporte y te devolvemos el pago de la consulta con ${partes.medicoNombre}.${detalle}`);
      await this.avisar(partes.medicoUsuarioId, pago, 'Reporte resuelto a favor del paciente', `El pago de la consulta con ${partes.pacienteNombre} se reembolsó al paciente.${detalle}`);
    } else {
      await this.avisar(partes.pacienteUsuarioId, pago, 'Reporte resuelto', `Revisamos tu reporte sobre la consulta con ${partes.medicoNombre} y el pago se liberó al médico.${detalle}`);
      await this.avisar(partes.medicoUsuarioId, pago, 'Pago liberado', `Se resolvió el reporte de ${partes.pacienteNombre} y el pago de la consulta se liberó a tu favor.${detalle}`);
    }
    return { pago, partes };
  }

  private avisar(usuarioId: string, pago: Pago, titulo: string, mensaje: string): Promise<void> {
    return this.notificador.notificar({ usuarioId, tipo: 'PAGO', titulo, mensaje, datos: { citaId: pago.citaId, pagoId: pago.id } });
  }
}
