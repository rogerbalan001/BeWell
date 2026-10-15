import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { CategoriaClinica, categoriaDe, TipoEvento } from './categoria-clinica';

export interface PropsEventoClinico {
  id: string;
  expedienteId: string;
  pacienteId: string;
  tipo: TipoEvento;
  categoria: CategoriaClinica;
  fecha: Date;
  titulo: string;
  /** Contenido clínico (cifrado a nivel de campo en la base de datos). */
  resumen: string;
  medicoId?: string;
  autorUsuarioId?: string;
  /** Documento que originó el evento: cita, examen, récipe, referencia… */
  documentoOrigenId?: string;
  detalles: Record<string, string>;
  creadoEn: Date;
}

/** «Entity» EventoClinico: un elemento de la línea de tiempo del paciente. */
export class EventoClinico implements PropsEventoClinico {
  id: string;
  expedienteId: string;
  pacienteId: string;
  tipo: TipoEvento;
  categoria: CategoriaClinica;
  fecha: Date;
  titulo: string;
  resumen: string;
  medicoId?: string;
  autorUsuarioId?: string;
  documentoOrigenId?: string;
  detalles: Record<string, string>;
  creadoEn: Date;

  constructor(props: PropsEventoClinico) {
    Object.assign(this, props);
  }

  static registrar(
    datos: Omit<PropsEventoClinico, 'id' | 'categoria' | 'creadoEn' | 'detalles'> & {
      categoria?: CategoriaClinica;
      detalles?: Record<string, string>;
    },
    ahora: Date,
  ): EventoClinico {
    asegurar(Object.values(TipoEvento).includes(datos.tipo), `Tipo de evento inválido: ${datos.tipo}`);
    asegurar(datos.titulo?.trim(), 'El evento requiere un título');
    asegurar(!isNaN(datos.fecha.getTime()), 'Fecha del evento inválida');
    return new EventoClinico({
      ...datos,
      id: generarId(),
      categoria: datos.categoria ?? categoriaDe(datos.tipo),
      titulo: datos.titulo.trim(),
      resumen: (datos.resumen ?? '').trim(),
      detalles: datos.detalles ?? {},
      creadoEn: ahora,
    });
  }
}
