import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

export type Sexo = 'F' | 'M' | 'OTRO';
export const PARENTESCO_TITULAR = 'TITULAR';

export interface DatosPersonales {
  nombres: string;
  apellidos: string;
  cedula?: string;
  fechaNacimiento: Date;
  sexo: Sexo;
}

export interface PropsPerfilPaciente extends DatosPersonales {
  id: string;
  titularUsuarioId: string;
  parentescoConTitular: string;
  creadoEn: Date;
}

/**
 * «Entity» PerfilPaciente. Un usuario titular gestiona uno o varios perfiles
 * (el propio y los de sus dependientes). Se relaciona con Usuario por
 * asociación, no por herencia: un dependiente no necesita cuenta propia.
 */
export class PerfilPaciente implements PropsPerfilPaciente {
  id: string;
  titularUsuarioId: string;
  parentescoConTitular: string;
  nombres: string;
  apellidos: string;
  cedula?: string;
  fechaNacimiento: Date;
  sexo: Sexo;
  creadoEn: Date;

  constructor(props: PropsPerfilPaciente) {
    Object.assign(this, props);
  }

  static crear(titularUsuarioId: string, parentesco: string, datos: DatosPersonales, ahora: Date): PerfilPaciente {
    PerfilPaciente.validar(datos, ahora);
    return new PerfilPaciente({
      id: generarId(),
      titularUsuarioId,
      parentescoConTitular: parentesco.trim().toUpperCase(),
      ...datos,
      nombres: datos.nombres.trim(),
      apellidos: datos.apellidos.trim(),
      cedula: datos.cedula?.trim() || undefined,
      creadoEn: ahora,
    });
  }

  actualizar(datos: Partial<DatosPersonales>, ahora: Date): void {
    const definidos = Object.fromEntries(Object.entries(datos).filter(([, v]) => v !== undefined));
    const nuevos: DatosPersonales = { ...this.datos(), ...definidos };
    PerfilPaciente.validar(nuevos, ahora);
    Object.assign(this, nuevos);
  }

  get nombreCompleto(): string {
    return `${this.nombres} ${this.apellidos}`;
  }

  get esTitular(): boolean {
    return this.parentescoConTitular === PARENTESCO_TITULAR;
  }

  edad(ahora: Date): number {
    let edad = ahora.getUTCFullYear() - this.fechaNacimiento.getUTCFullYear();
    const m = ahora.getUTCMonth() - this.fechaNacimiento.getUTCMonth();
    if (m < 0 || (m === 0 && ahora.getUTCDate() < this.fechaNacimiento.getUTCDate())) edad--;
    return edad;
  }

  esGestionadoPor(usuarioId: string): boolean {
    return this.titularUsuarioId === usuarioId;
  }

  private datos(): DatosPersonales {
    const { nombres, apellidos, cedula, fechaNacimiento, sexo } = this;
    return { nombres, apellidos, cedula, fechaNacimiento, sexo };
  }

  private static validar(datos: DatosPersonales, ahora: Date): void {
    asegurar(datos.nombres?.trim(), 'Los nombres son obligatorios');
    asegurar(datos.apellidos?.trim(), 'Los apellidos son obligatorios');
    asegurar(!isNaN(datos.fechaNacimiento?.getTime()), 'Fecha de nacimiento inválida');
    asegurar(datos.fechaNacimiento <= ahora, 'La fecha de nacimiento no puede ser futura');
    asegurar(['F', 'M', 'OTRO'].includes(datos.sexo), 'Sexo inválido');
  }
}
