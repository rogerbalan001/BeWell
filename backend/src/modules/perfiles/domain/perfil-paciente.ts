import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

export type Sexo = 'F' | 'M' | 'OTRO';
export const PARENTESCO_TITULAR = 'TITULAR';
/** Parentesco de un perfil que pasó a ser gestionado por la propia persona al cumplir la mayoría de edad. */
export const PARENTESCO_INDEPENDIENTE = 'INDEPENDIENTE';
export const EDAD_MAYORIA = 18;

/** Pedido de un dependiente mayor de edad para gestionar su propio perfil desde su cuenta. */
export interface SolicitudControl {
  usuarioId: string;
  solicitadaEn: Date;
}

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
  solicitudControl?: SolicitudControl;
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
  solicitudControl?: SolicitudControl;

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

  esMayorDeEdad(ahora: Date): boolean {
    return this.edad(ahora) >= EDAD_MAYORIA;
  }

  /** HU perfiles: al cumplir la mayoría de edad, el dependiente puede pedir el control de su perfil. */
  solicitarControl(usuarioId: string, ahora: Date): void {
    asegurar(!this.esTitular, 'Este perfil ya es el titular de su cuenta');
    asegurar(this.esMayorDeEdad(ahora), `Solo un dependiente con ${EDAD_MAYORIA} años o más puede pedir el control de su perfil`);
    asegurar(this.titularUsuarioId !== usuarioId, 'Ya gestionas este perfil');
    this.solicitudControl = { usuarioId, solicitadaEn: ahora };
  }

  /** El titular entrega el perfil: pasa a la cuenta de la persona, con su expediente completo. */
  aprobarControl(ahora: Date): void {
    const solicitud = this.solicitudControl;
    asegurar(solicitud, 'No hay una solicitud de control pendiente');
    asegurar(this.esMayorDeEdad(ahora), `El perfil todavía no cumple ${EDAD_MAYORIA} años`);
    this.titularUsuarioId = solicitud.usuarioId;
    this.parentescoConTitular = PARENTESCO_INDEPENDIENTE;
    this.solicitudControl = undefined;
  }

  rechazarControl(): void {
    asegurar(this.solicitudControl, 'No hay una solicitud de control pendiente');
    this.solicitudControl = undefined;
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
