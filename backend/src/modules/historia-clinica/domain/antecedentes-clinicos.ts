import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

export const GRUPOS_SANGUINEOS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as const;
export type GrupoSanguineo = (typeof GRUPOS_SANGUINEOS)[number];

/** Hábitos psicobiológicos de la anamnesis. */
export interface Habitos {
  tabaco?: string;
  alcohol?: string;
  drogas?: string;
  actividadFisica?: string;
  alimentacion?: string;
  sueno?: string;
}

/** Antecedentes gineco-obstétricos (solo aplican a pacientes de sexo femenino). */
export interface AntecedentesGinecoObstetricos {
  menarquia?: string;
  ultimaMenstruacion?: string;
  gestas?: number;
  partos?: number;
  cesareas?: number;
  abortos?: number;
  metodoAnticonceptivo?: string;
}

/** Contenido clínico de los antecedentes (se guarda cifrado a nivel de campo). */
export interface DatosAntecedentes {
  grupoSanguineo?: GrupoSanguineo;
  patologicos: string[];
  quirurgicos: string[];
  alergicos: string[];
  medicamentosActuales: string[];
  hospitalizaciones: string[];
  inmunizaciones: string[];
  familiares: string[];
  habitos: Habitos;
  ginecoObstetricos?: AntecedentesGinecoObstetricos;
}

export const ANTECEDENTES_VACIOS: DatosAntecedentes = {
  patologicos: [],
  quirurgicos: [],
  alergicos: [],
  medicamentosActuales: [],
  hospitalizaciones: [],
  inmunizaciones: [],
  familiares: [],
  habitos: {},
};

const LISTAS = ['patologicos', 'quirurgicos', 'alergicos', 'medicamentosActuales', 'hospitalizaciones', 'inmunizaciones', 'familiares'] as const;
const MAX_ELEMENTOS = 50;
const MAX_TEXTO = 300;

const limpiarLista = (valores: string[] | undefined, nombre: string): string[] => {
  const lista = [...new Set((valores ?? []).map((v) => v.trim()).filter(Boolean))];
  asegurar(lista.length <= MAX_ELEMENTOS, `Máximo ${MAX_ELEMENTOS} elementos en ${nombre}`);
  asegurar(lista.every((v) => v.length <= MAX_TEXTO), `Cada elemento de ${nombre} admite máximo ${MAX_TEXTO} caracteres`);
  return lista;
};

const limpiarTexto = (valor: string | undefined): string | undefined => {
  const t = valor?.trim();
  if (!t) return undefined;
  asegurar(t.length <= MAX_TEXTO, `Los textos de la historia clínica admiten máximo ${MAX_TEXTO} caracteres`);
  return t;
};

const conteo = (valor: number | undefined, nombre: string): number | undefined => {
  if (valor === undefined || valor === null) return undefined;
  asegurar(Number.isInteger(valor) && valor >= 0 && valor <= 30, `${nombre} debe ser un número entero entre 0 y 30`);
  return valor;
};

/**
 * «Entity» AntecedentesClinicos: la parte estable de la historia clínica del
 * paciente (anamnesis remota). Hay un documento por paciente, independiente
 * del médico; lo completa el paciente o un médico con permiso de escritura.
 */
export class AntecedentesClinicos {
  constructor(
    readonly id: string,
    readonly pacienteId: string,
    public datos: DatosAntecedentes,
    public actualizadoEn: Date,
    public actualizadoPorUsuarioId?: string,
    public actualizadoPorMedicoId?: string,
  ) {}

  static abrir(pacienteId: string, ahora: Date): AntecedentesClinicos {
    return new AntecedentesClinicos(generarId(), pacienteId, structuredClone(ANTECEDENTES_VACIOS), ahora);
  }

  /** Reemplaza los antecedentes. `admiteGineco` depende del sexo del paciente. */
  actualizar(
    datos: Partial<DatosAntecedentes>,
    autor: { usuarioId: string; medicoId?: string },
    admiteGineco: boolean,
    ahora: Date,
  ): void {
    asegurar(
      datos.grupoSanguineo === undefined || GRUPOS_SANGUINEOS.includes(datos.grupoSanguineo),
      `Grupo sanguíneo inválido: ${datos.grupoSanguineo}`,
    );
    const nuevos: DatosAntecedentes = { ...structuredClone(ANTECEDENTES_VACIOS), grupoSanguineo: datos.grupoSanguineo };
    for (const campo of LISTAS) nuevos[campo] = limpiarLista(datos[campo], campo);
    const h = datos.habitos ?? {};
    nuevos.habitos = Object.fromEntries(
      (['tabaco', 'alcohol', 'drogas', 'actividadFisica', 'alimentacion', 'sueno'] as const)
        .map((k) => [k, limpiarTexto(h[k])])
        .filter(([, v]) => v !== undefined),
    );
    if (datos.ginecoObstetricos) {
      asegurar(admiteGineco, 'Los antecedentes gineco-obstétricos solo aplican a pacientes de sexo femenino');
      const g = datos.ginecoObstetricos;
      const gineco: AntecedentesGinecoObstetricos = {
        menarquia: limpiarTexto(g.menarquia),
        ultimaMenstruacion: limpiarTexto(g.ultimaMenstruacion),
        gestas: conteo(g.gestas, 'Gestas'),
        partos: conteo(g.partos, 'Partos'),
        cesareas: conteo(g.cesareas, 'Cesáreas'),
        abortos: conteo(g.abortos, 'Abortos'),
        metodoAnticonceptivo: limpiarTexto(g.metodoAnticonceptivo),
      };
      const resueltos = (gineco.partos ?? 0) + (gineco.cesareas ?? 0) + (gineco.abortos ?? 0);
      asegurar(gineco.gestas === undefined || resueltos <= gineco.gestas, 'Partos + cesáreas + abortos no puede superar el número de gestas');
      nuevos.ginecoObstetricos = Object.fromEntries(Object.entries(gineco).filter(([, v]) => v !== undefined));
    }
    this.datos = nuevos;
    this.actualizadoEn = ahora;
    this.actualizadoPorUsuarioId = autor.usuarioId;
    this.actualizadoPorMedicoId = autor.medicoId;
  }

  get tieneAlergias(): boolean {
    return this.datos.alergicos.length > 0;
  }
}
