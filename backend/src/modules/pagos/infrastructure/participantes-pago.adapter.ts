import { Injectable } from '@nestjs/common';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { ParticipantesPago, ParticipantesPagoPuerto } from '../application/participantes-pago';
import { Pago } from '../domain/pago';

/** Obtiene las partes de un pago desde los módulos de perfiles y médicos. */
@Injectable()
export class ParticipantesPagoAdapter extends ParticipantesPagoPuerto {
  constructor(
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
  ) {
    super();
  }

  async de(pago: Pago): Promise<ParticipantesPago> {
    const [paciente, medico] = await Promise.all([this.perfiles.obtener(pago.pacienteId), this.medicos.obtener(pago.medicoId)]);
    return {
      pacienteNombre: paciente.nombreCompleto,
      pacienteUsuarioId: paciente.titularUsuarioId,
      medicoNombre: medico.nombreCompleto,
      medicoUsuarioId: medico.usuarioId,
    };
  }
}
