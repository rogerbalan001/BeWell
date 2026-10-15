import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';
import { CategoriaClinica } from './categoria-clinica';

export type OrigenPermiso = 'PACIENTE' | 'REFERENCIA';

export interface PropsPermisoAcceso {
  id: string;
  expedienteId: string;
  pacienteId: string;
  medicoId: string;
  categoriasPermitidas: CategoriaClinica[];
  /** Si es true el médico también puede agregar eventos en esas categorías. */
  escritura: boolean;
  validoHasta: Date;
  revocado: boolean;
  revocadoEn?: Date;
  otorgadoPorUsuarioId: string;
  origen: OrigenPermiso;
  creadoEn: Date;
}

/**
 * «Entity» PermisoAcceso: implementa el control de privacidad. El paciente
 * autoriza a un médico, para ciertas secciones y hasta una fecha. Se guarda
 * en su propia colección para conservar el historial de permisos (D4).
 */
export class PermisoAcceso implements PropsPermisoAcceso {
  id: string;
  expedienteId: string;
  pacienteId: string;
  medicoId: string;
  categoriasPermitidas: CategoriaClinica[];
  escritura: boolean;
  validoHasta: Date;
  revocado: boolean;
  revocadoEn?: Date;
  otorgadoPorUsuarioId: string;
  origen: OrigenPermiso;
  creadoEn: Date;

  constructor(props: PropsPermisoAcceso) {
    Object.assign(this, props);
  }

  static conceder(
    datos: Omit<PropsPermisoAcceso, 'id' | 'revocado' | 'revocadoEn' | 'creadoEn'>,
    ahora: Date,
  ): PermisoAcceso {
    asegurar(datos.categoriasPermitidas.length > 0, 'Selecciona al menos una sección del expediente');
    asegurar(datos.validoHasta > ahora, 'La fecha de vencimiento debe ser futura');
    return new PermisoAcceso({
      ...datos,
      categoriasPermitidas: [...new Set(datos.categoriasPermitidas)],
      id: generarId(),
      revocado: false,
      creadoEn: ahora,
    });
  }

  estaVigente(fecha: Date): boolean {
    return !this.revocado && fecha < this.validoHasta;
  }

  permiteLeer(categoria: CategoriaClinica, fecha: Date): boolean {
    return this.estaVigente(fecha) && this.categoriasPermitidas.includes(categoria);
  }

  permiteEscribir(categoria: CategoriaClinica, fecha: Date): boolean {
    return this.escritura && this.permiteLeer(categoria, fecha);
  }

  /** La revocación aplica de inmediato. */
  revocar(ahora: Date): void {
    this.revocado = true;
    this.revocadoEn = ahora;
  }
}
