import { ExamenMedico } from './examen-medico';
import { SolicitudExamen } from './solicitud-examen';

export abstract class ExamenRepository {
  abstract guardar(examen: ExamenMedico): Promise<void>;
  abstract buscarPorId(id: string): Promise<ExamenMedico | null>;
  abstract listarPorPaciente(pacienteId: string): Promise<ExamenMedico[]>;
}

export abstract class SolicitudExamenRepository {
  abstract guardar(solicitud: SolicitudExamen): Promise<void>;
  abstract buscarPorId(id: string): Promise<SolicitudExamen | null>;
  abstract listarPorPaciente(pacienteId: string): Promise<SolicitudExamen[]>;
  abstract listarPorMedico(medicoId: string): Promise<SolicitudExamen[]>;
}
