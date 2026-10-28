import { CategoriaClinica, TipoEvento } from './categoria-clinica';
import { EventoClinico } from './evento-clinico';
import { ExpedienteClinico } from './expediente-clinico';
import { PermisoAcceso } from './permiso-acceso';
import { ReferenciaEspecialista } from './referencia-especialista';

export interface Paginacion {
  pagina: number;
  tamano: number;
}

export abstract class ExpedienteRepository {
  abstract guardar(expediente: ExpedienteClinico): Promise<void>;
  abstract buscarPorPaciente(pacienteId: string): Promise<ExpedienteClinico | null>;
}

export abstract class PermisoAccesoRepository {
  abstract guardar(permiso: PermisoAcceso): Promise<void>;
  abstract buscarPorId(id: string): Promise<PermisoAcceso | null>;
  abstract buscarVigentes(pacienteId: string, medicoId: string, fecha: Date): Promise<PermisoAcceso[]>;
  abstract listarPorPaciente(pacienteId: string): Promise<PermisoAcceso[]>;
  abstract listarVigentesPorMedico(medicoId: string, fecha: Date): Promise<PermisoAcceso[]>;
}

export abstract class EventoClinicoRepository {
  abstract guardar(evento: EventoClinico): Promise<void>;
  abstract buscarPorId(id: string): Promise<EventoClinico | null>;
  /** Línea de tiempo paginada, del más reciente al más antiguo. */
  abstract listarPorPaciente(
    pacienteId: string,
    categorias: CategoriaClinica[],
    tipo: TipoEvento | undefined,
    paginacion: Paginacion,
  ): Promise<{ items: EventoClinico[]; total: number }>;
  /**
   * Agrega o reemplaza claves de `detalles` en los eventos generados por un
   * documento de otro módulo (p. ej. el estado de una orden de exámenes).
   */
  abstract actualizarDetallesPorDocumento(documentoOrigenId: string, tipo: TipoEvento, detalles: Record<string, string>): Promise<void>;
}

export abstract class ReferenciaRepository {
  abstract guardar(referencia: ReferenciaEspecialista): Promise<void>;
  abstract buscarPorId(id: string): Promise<ReferenciaEspecialista | null>;
  abstract listarPorPacientes(pacienteIds: string[]): Promise<ReferenciaEspecialista[]>;
  abstract listarPorMedico(medicoId: string): Promise<ReferenciaEspecialista[]>;
}
