import { createHash, randomBytes } from 'crypto';
import { asegurar } from '../../../shared/domain/errores';
import { generarId } from '../../../shared/domain/id';

/** «Entity» embebida ContactoEmergencia. */
export interface ContactoEmergencia {
  nombre: string;
  parentesco: string;
  telefono: string;
}

export type CampoFicha = 'grupoSanguineo' | 'alergias' | 'condicionesCronicas' | 'medicacionActual' | 'contactos';
export const CAMPOS_FICHA: CampoFicha[] = ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'medicacionActual', 'contactos'];
/** HU: tipo de sangre, alergias, condiciones críticas y contacto, sin iniciar sesión. */
export const CAMPOS_PUBLICOS_POR_DEFECTO: CampoFicha[] = ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'contactos'];
export const GRUPOS_SANGUINEOS = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

export interface DatosFicha {
  grupoSanguineo?: string;
  alergias: string[];
  condicionesCronicas: string[];
  medicacionActual: string[];
  contactos: ContactoEmergencia[];
  camposPublicos: CampoFicha[];
}

export interface PropsFicha extends DatosFicha {
  id: string;
  pacienteId: string;
  /** SHA-256 del token del QR: nunca se guarda el token. */
  tokenQrHash?: string;
  qrGeneradoEn?: Date;
  actualizadoEn: Date;
}

/** Vista que se entrega al escanear el QR. */
export interface VistaFicha {
  nivel: 'PUBLICO' | 'AMPLIADO';
  grupoSanguineo?: string;
  alergias?: string[];
  condicionesCronicas?: string[];
  medicacionActual?: string[];
  contactos?: ContactoEmergencia[];
  actualizadoEn: Date;
}

/** «Entity» FichaEmergencia: subconjunto mínimo (IPS) accesible por QR. */
export class FichaEmergencia implements PropsFicha {
  id: string;
  pacienteId: string;
  tokenQrHash?: string;
  qrGeneradoEn?: Date;
  grupoSanguineo?: string;
  alergias: string[];
  condicionesCronicas: string[];
  medicacionActual: string[];
  contactos: ContactoEmergencia[];
  camposPublicos: CampoFicha[];
  actualizadoEn: Date;

  constructor(props: PropsFicha) {
    Object.assign(this, props);
  }

  static vacia(pacienteId: string, ahora: Date): FichaEmergencia {
    return new FichaEmergencia({
      id: generarId(),
      pacienteId,
      alergias: [],
      condicionesCronicas: [],
      medicacionActual: [],
      contactos: [],
      camposPublicos: [...CAMPOS_PUBLICOS_POR_DEFECTO],
      actualizadoEn: ahora,
    });
  }

  static hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  actualizar(datos: DatosFicha, ahora: Date): void {
    asegurar(!datos.grupoSanguineo || GRUPOS_SANGUINEOS.includes(datos.grupoSanguineo), 'Grupo sanguíneo inválido');
    asegurar(datos.contactos.length <= 5, 'Máximo 5 contactos de emergencia');
    for (const c of datos.contactos) asegurar(c.nombre?.trim() && c.telefono?.trim(), 'Cada contacto necesita nombre y teléfono');
    asegurar(datos.camposPublicos.every((c) => CAMPOS_FICHA.includes(c)), 'Campo público inválido');
    const limpiar = (l: string[]) => l.map((x) => x.trim()).filter(Boolean);
    Object.assign(this, {
      grupoSanguineo: datos.grupoSanguineo || undefined,
      alergias: limpiar(datos.alergias),
      condicionesCronicas: limpiar(datos.condicionesCronicas),
      medicacionActual: limpiar(datos.medicacionActual),
      contactos: datos.contactos.map((c) => ({ nombre: c.nombre.trim(), parentesco: c.parentesco?.trim() ?? '', telefono: c.telefono.trim() })),
      camposPublicos: [...new Set(datos.camposPublicos)],
      actualizadoEn: ahora,
    });
  }

  /** Genera un token aleatorio de 128 bits; el anterior queda invalidado. Devuelve el token en claro una sola vez. */
  regenerarToken(ahora: Date): { token: string; hashAnterior?: string } {
    const hashAnterior = this.tokenQrHash;
    const token = randomBytes(16).toString('base64url');
    this.tokenQrHash = FichaEmergencia.hashToken(token);
    this.qrGeneradoEn = ahora;
    return { token, hashAnterior };
  }

  /** El QR no muestra el resto del expediente: solo los campos de la ficha. */
  vista(ampliada: boolean): VistaFicha {
    const visible = (c: CampoFicha) => ampliada || this.camposPublicos.includes(c);
    return {
      nivel: ampliada ? 'AMPLIADO' : 'PUBLICO',
      grupoSanguineo: visible('grupoSanguineo') ? this.grupoSanguineo : undefined,
      alergias: visible('alergias') ? this.alergias : undefined,
      condicionesCronicas: visible('condicionesCronicas') ? this.condicionesCronicas : undefined,
      medicacionActual: visible('medicacionActual') ? this.medicacionActual : undefined,
      contactos: visible('contactos') ? this.contactos : undefined,
      actualizadoEn: this.actualizadoEn,
    };
  }
}

export abstract class FichaEmergenciaRepository {
  abstract guardar(ficha: FichaEmergencia): Promise<void>;
  abstract buscarPorPaciente(pacienteId: string): Promise<FichaEmergencia | null>;
  abstract buscarPorTokenHash(hash: string): Promise<FichaEmergencia | null>;
}
