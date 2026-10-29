import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import {
  CLAVES_HABITOS,
  CLAVES_IDENTIFICACION,
  limpiarTextos,
  LISTAS_PERSONALES,
  Textos,
  TIPOS_FAMILIARES,
} from './catalogo-historia';

export const GRUPOS_SANGUINEOS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as const;
export type GrupoSanguineo = (typeof GRUPOS_SANGUINEOS)[number];

export type ListaPersonal = (typeof LISTAS_PERSONALES)[number];
export type TipoFamiliar = (typeof TIPOS_FAMILIARES)[number];
export type Habitos = Textos<(typeof CLAVES_HABITOS)[number]>;
/** Identificación del encabezado que no está en el perfil (lugar de nacimiento, religión, contacto…). */
export type DatosSociales = Textos<(typeof CLAVES_IDENTIFICACION)[number]>;

/** III.10 Antecedentes ginecobstétricos (solo aplican a pacientes de sexo femenino). */
export interface AntecedentesGinecoObstetricos {
  menarquia?: string;
  ultimaMenstruacion?: string;
  /** Embarazos. */
  gestas?: number;
  partos?: number;
  cesareas?: number;
  abortos?: number;
  perdidasFetales?: number;
  eclampsia?: string;
  menopausia?: string;
  trastornosMenstruales?: string;
  metodoAnticonceptivo?: string;
}

/**
 * Contenido clínico de los antecedentes (se guarda cifrado a nivel de campo).
 * Sigue el encabezado y las secciones III a V del modelo de historia clínica integral.
 */
export type DatosAntecedentes = {
  grupoSanguineo?: GrupoSanguineo;
  datosSociales: DatosSociales;
  ginecoObstetricos?: AntecedentesGinecoObstetricos;
  /** IV. Antecedentes familiares por tipo (alérgicos, metabólicos, neoplasias…). */
  familiares: Partial<Record<TipoFamiliar, string[]>>;
  /** V. Historia personal y social. */
  habitos: Habitos;
  /** V. Medicamentos que toma actualmente. */
  medicamentosActuales: string[];
} & Record<ListaPersonal, string[]>;

export const ANTECEDENTES_VACIOS: DatosAntecedentes = {
  datosSociales: {},
  familiares: {},
  habitos: {},
  medicamentosActuales: [],
  ...(Object.fromEntries(LISTAS_PERSONALES.map((k) => [k, []])) as unknown as Record<ListaPersonal, string[]>),
};

const MAX_ELEMENTOS = 50;
const MAX_TEXTO = 300;

const limpiarLista = (valores: unknown, nombre: string): string[] => {
  asegurar(valores === undefined || valores === null || Array.isArray(valores), `${nombre} debe ser una lista`);
  const lista = [...new Set(((valores as unknown[]) ?? []).map((v) => String(v).trim()).filter(Boolean))];
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

/** Antecedentes familiares guardados antes como una sola lista pasan a "otros". */
export const normalizarFamiliares = (v: unknown): Partial<Record<TipoFamiliar, string[]>> =>
  Array.isArray(v) ? (v.length ? { otros: v.map(String) } : {}) : ((v as Partial<Record<TipoFamiliar, string[]>>) ?? {});

/**
 * «Entity» AntecedentesClinicos: la parte estable de la historia clínica del
 * paciente (identificación y anamnesis remota). Hay un documento por paciente,
 * independiente del médico; lo completa el paciente o un médico con permiso de escritura.
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
    for (const campo of LISTAS_PERSONALES) nuevos[campo] = limpiarLista(datos[campo], campo);
    nuevos.medicamentosActuales = limpiarLista(datos.medicamentosActuales, 'medicamentosActuales');
    const familiares = normalizarFamiliares(datos.familiares);
    nuevos.familiares = {};
    for (const tipo of TIPOS_FAMILIARES) {
      const lista = limpiarLista(familiares[tipo], `familiares ${tipo}`);
      if (lista.length) nuevos.familiares[tipo] = lista;
    }
    nuevos.habitos = limpiarTextos(datos.habitos, CLAVES_HABITOS, MAX_TEXTO, 'Hábitos');
    nuevos.datosSociales = limpiarTextos(datos.datosSociales, CLAVES_IDENTIFICACION, MAX_TEXTO, 'Identificación');
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
        perdidasFetales: conteo(g.perdidasFetales, 'Pérdidas fetales'),
        eclampsia: limpiarTexto(g.eclampsia),
        menopausia: limpiarTexto(g.menopausia),
        trastornosMenstruales: limpiarTexto(g.trastornosMenstruales),
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
