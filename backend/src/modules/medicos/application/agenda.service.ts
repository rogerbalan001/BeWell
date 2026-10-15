import { Injectable } from '@nestjs/common';
import { Actor } from '../../../shared/domain/roles';
import { BloqueHorario } from '../domain/bloque-horario';
import { Medico, Modalidad } from '../domain/medico';
import { MedicoRepository } from '../domain/medico.repository';
import { TipoPolitica } from '../domain/politica-cancelacion';
import { MedicosService } from './medicos.service';

/** «Control» HU: configurar horario y política de cancelación del médico. */
@Injectable()
export class AgendaService {
  constructor(
    private readonly medicos: MedicoRepository,
    private readonly medicosService: MedicosService,
  ) {}

  obtenerAgenda(actor: Actor): Promise<Medico> {
    return this.medicosService.delActor(actor);
  }

  async configurarHorario(actor: Actor, bloques: BloqueHorario[], modalidades?: Modalidad[]): Promise<Medico> {
    const medico = await this.medicosService.delActor(actor);
    medico.configurarHorario(bloques, modalidades);
    await this.medicos.guardar(medico);
    return medico;
  }

  async configurarPolitica(actor: Actor, tipo: TipoPolitica): Promise<Medico> {
    const medico = await this.medicosService.delActor(actor);
    medico.configurarPolitica(tipo);
    await this.medicos.guardar(medico);
    return medico;
  }
}
