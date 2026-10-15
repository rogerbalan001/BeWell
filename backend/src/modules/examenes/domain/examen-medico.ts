import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

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

  constructor(props: PropsExamen) {
    Object.assign(this, props);
  }

  static cargar(
    datos: Omit<PropsExamen, 'id' | 'estadoExtraccion' | 'resultados' | 'cargadoEn' | 'validadoPorMedicoId'>,
    ahora: Date,
  ): ExamenMedico {
    asegurar(datos.titulo?.trim(), 'Indica el nombre del examen');
    return new ExamenMedico({
      ...datos,
      id: generarId(),
      titulo: datos.titulo.trim(),
      estadoExtraccion: EstadoExtraccion.NO_RECONOCIDO,
      resultados: [],
      cargadoEn: ahora,
    });
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
