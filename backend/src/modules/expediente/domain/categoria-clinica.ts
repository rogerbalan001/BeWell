/** Secciones del expediente sobre las que el paciente concede permisos. */
export enum CategoriaClinica {
  CONSULTAS = 'CONSULTAS',
  DIAGNOSTICOS = 'DIAGNOSTICOS',
  LABORATORIOS = 'LABORATORIOS',
  CIRUGIAS = 'CIRUGIAS',
  VACUNAS = 'VACUNAS',
  RECETAS = 'RECETAS',
  SALUD_MENTAL = 'SALUD_MENTAL',
}

export const TODAS_LAS_CATEGORIAS = Object.values(CategoriaClinica);

/** Tipos de evento de la línea de tiempo (HU: consultas, diagnósticos, cirugías, vacunas, exámenes). */
export enum TipoEvento {
  CONSULTA = 'CONSULTA',
  DIAGNOSTICO = 'DIAGNOSTICO',
  CIRUGIA = 'CIRUGIA',
  VACUNA = 'VACUNA',
  EXAMEN = 'EXAMEN',
  SOLICITUD_EXAMEN = 'SOLICITUD_EXAMEN',
  RECETA = 'RECETA',
  REFERENCIA = 'REFERENCIA',
  NOTA_SALUD_MENTAL = 'NOTA_SALUD_MENTAL',
}

const CATEGORIA_POR_TIPO: Record<TipoEvento, CategoriaClinica> = {
  [TipoEvento.CONSULTA]: CategoriaClinica.CONSULTAS,
  [TipoEvento.DIAGNOSTICO]: CategoriaClinica.DIAGNOSTICOS,
  [TipoEvento.CIRUGIA]: CategoriaClinica.CIRUGIAS,
  [TipoEvento.VACUNA]: CategoriaClinica.VACUNAS,
  [TipoEvento.EXAMEN]: CategoriaClinica.LABORATORIOS,
  [TipoEvento.SOLICITUD_EXAMEN]: CategoriaClinica.LABORATORIOS,
  [TipoEvento.RECETA]: CategoriaClinica.RECETAS,
  [TipoEvento.REFERENCIA]: CategoriaClinica.CONSULTAS,
  [TipoEvento.NOTA_SALUD_MENTAL]: CategoriaClinica.SALUD_MENTAL,
};

export const categoriaDe = (tipo: TipoEvento): CategoriaClinica => CATEGORIA_POR_TIPO[tipo];
