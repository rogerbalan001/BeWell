import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { categoriaValida, ClasificacionExamen, tipoNormalizado } from './clasificacion-examen';

/** Nombre que recibe un examen sin título y sin clasificar. */
export const TITULO_SIN_CLASIFICAR = 'Examen sin clasificar';

/** «Entity» embebida ResultadoAnalito (equivalente a Observation en FHIR). */
export interface ResultadoAnalito {
  analito: string;
  valor: string;
  unidad?: string;
  rangoReferencia?: string;
  /** 0–1. Ausente si el valor lo cargó una persona. */
  confianzaOcr?: number;
  /** Un dato extraído por IA no es clínicamente confiable hasta que un médico lo revisa. */
  validadoPorMedico: boolean;
}

export enum EstadoExtraccion {
  /** El OCR detectó valores; el paciente debe revisarlos y confirmarlos. */
  EXTRAIDO = 'EXTRAIDO',
  /** El paciente confirmó o corrigió los valores. */
  CONFIRMADO = 'CONFIRMADO',
  /** El OCR no reconoció el documento: queda guardado como archivo adjunto. */
  NO_RECONOCIDO = 'NO_RECONOCIDO',
}

export interface PropsExamen {
  id: string;
  pacienteId: string;
  solicitudId?: string;
  titulo: string;
  fechaExamen?: Date;
  archivoRef: string;
  tipoMime: string;
  nombreArchivo: string;
  tamanoBytes: number;
  estadoExtraccion: EstadoExtraccion;
  resultados: ResultadoAnalito[];
  cargadoPorUsuarioId: string;
  cargadoEn: Date;
  validadoPorMedicoId?: string;
  /** Categoría y tipo sugeridos por la IA o elegidos por el paciente. */
  clasificacion?: ClasificacionExamen;
  /** El título no lo escribió el paciente: se toma del tipo y cambia si se corrige la clasificación. */
  tituloAutomatico?: boolean;
}

/** «Entity» ExamenMedico: guarda solo la referencia al archivo en el almacenamiento de objetos. */
export class ExamenMedico implements PropsExamen {
  id: string;
  pacienteId: string;
  solicitudId?: string;
  titulo: string;
  fechaExamen?: Date;
  archivoRef: string;
  tipoMime: string;
  nombreArchivo: string;
  tamanoBytes: number;
  estadoExtraccion: EstadoExtraccion;
  resultados: ResultadoAnalito[];
  cargadoPorUsuarioId: string;
  cargadoEn: Date;
  validadoPorMedicoId?: string;
  clasificacion?: ClasificacionExamen;
  tituloAutomatico?: boolean;

  constructor(props: PropsExamen) {
    Object.assign(this, props);
  }

  static cargar(
    datos: Omit<PropsExamen, 'id' | 'estadoExtraccion' | 'resultados' | 'cargadoEn' | 'validadoPorMedicoId' | 'clasificacion' | 'tituloAutomatico' | 'titulo'> & {
      titulo?: string;
    },
    ahora: Date,
  ): ExamenMedico {
    // El título es opcional: si el paciente no lo escribe, se toma del tipo que sugiera la IA.
    const titulo = datos.titulo?.trim() ?? '';
    return new ExamenMedico({
      ...datos,
      id: generarId(),
      titulo: titulo || TITULO_SIN_CLASIFICAR,
      tituloAutomatico: !titulo,
      estadoExtraccion: EstadoExtraccion.NO_RECONOCIDO,
      resultados: [],
      cargadoEn: ahora,
    });
  }

  /** Guarda la sugerencia de la IA. Sin sugerencia, el examen queda sin clasificar y el paciente la elige. */
  registrarSugerencia(sugerencia: { categoria: string; tipo: string; confianza: number } | null): void {
    if (!sugerencia?.tipo?.trim()) return;
    this.aplicarClasificacion({
      categoria: categoriaValida(sugerencia.categoria),
      tipo: tipoNormalizado(sugerencia.tipo),
      confianza: Math.min(Math.max(sugerencia.confianza ?? 0, 0), 1),
      origen: 'IA',
    });
  }

  /** El paciente corrige la sugerencia o elige la categoría y el tipo si la IA no los reconoció. */
  corregirClasificacion(categoria: string, tipo: string): void {
    asegurar(tipo?.trim(), 'Indica el tipo de examen');
    this.aplicarClasificacion({ categoria: categoriaValida(categoria), tipo: tipoNormalizado(tipo), origen: 'PACIENTE' });
  }

  private aplicarClasificacion(c: ClasificacionExamen): void {
    this.clasificacion = c;
    if (this.tituloAutomatico) this.titulo = c.tipo;
  }

  /** Resultado del OCR: si no detectó nada, el examen queda como adjunto (degradación controlada). */
  registrarExtraccion(resultados: ResultadoAnalito[] | null): void {
    const validos = (resultados ?? []).filter((r) => r.analito?.trim() && r.valor?.toString().trim());
    this.resultados = validos.map((r) => ({ ...r, validadoPorMedico: false }));
    this.estadoExtraccion = validos.length ? EstadoExtraccion.EXTRAIDO : EstadoExtraccion.NO_RECONOCIDO;
  }

  /** El paciente corrige o completa los valores antes de guardarlos. */
  confirmarResultados(resultados: Omit<ResultadoAnalito, 'validadoPorMedico' | 'confianzaOcr'>[]): void {
    for (const r of resultados) {
      asegurar(r.analito?.trim() && `${r.valor ?? ''}`.trim(), 'Cada resultado necesita analito y valor');
    }
    const previos = new Map(this.resultados.map((r) => [r.analito, r]));
    this.resultados = resultados.map((r) => {
      const previo = previos.get(r.analito);
      const sinCambios = previo && previo.valor === r.valor && previo.unidad === r.unidad;
      return { ...r, confianzaOcr: sinCambios ? previo.confianzaOcr : undefined, validadoPorMedico: false };
    });
    this.estadoExtraccion = EstadoExtraccion.CONFIRMADO;
  }

  validarPorMedico(medicoId: string): void {
    asegurar(this.resultados.length > 0, 'No hay resultados para validar');
    this.resultados = this.resultados.map((r) => ({ ...r, validadoPorMedico: true }));
    this.validadoPorMedicoId = medicoId;
  }
}
