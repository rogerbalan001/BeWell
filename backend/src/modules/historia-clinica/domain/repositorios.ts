import { AntecedentesClinicos } from './antecedentes-clinicos';
import { ConsultaClinica } from './consulta-clinica';

export abstract class AntecedentesClinicosRepository {
  abstract guardar(antecedentes: AntecedentesClinicos): Promise<void>;
  abstract buscarPorPaciente(pacienteId: string): Promise<AntecedentesClinicos | null>;
}

export abstract class ConsultaClinicaRepository {
  abstract guardar(consulta: ConsultaClinica): Promise<void>;
  abstract buscarPorId(id: string): Promise<ConsultaClinica | null>;
  abstract buscarPorCita(citaId: string): Promise<ConsultaClinica | null>;
  /** Consultas del paciente, de la más reciente a la más antigua. */
  abstract listarPorPaciente(pacienteId: string): Promise<ConsultaClinica[]>;
}
