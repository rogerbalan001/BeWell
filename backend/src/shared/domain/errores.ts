/**
 * Errores de dominio. No dependen de NestJS: el filtro global
 * `ErroresDominioFilter` (capa Interfaz) los traduce a códigos HTTP.
 */
export class ErrorDominio extends Error {
  constructor(
    message: string,
    public readonly codigo: string = 'REGLA_DE_NEGOCIO',
  ) {
    super(message);
    this.name = new.target.name;
  }
}

/** Regla de negocio violada o datos inválidos (HTTP 400/422). */
export class ReglaNegocioError extends ErrorDominio {}

/** Recurso inexistente (HTTP 404). */
export class NoEncontradoError extends ErrorDominio {
  constructor(recurso: string, id?: string) {
    super(id ? `${recurso} ${id} no existe` : `${recurso} no existe`, 'NO_ENCONTRADO');
  }
}

/** El actor no tiene permiso sobre el recurso (HTTP 403). */
export class AccesoDenegadoError extends ErrorDominio {
  constructor(message = 'No tienes permiso para realizar esta acción') {
    super(message, 'ACCESO_DENEGADO');
  }
}

/** Conflicto con el estado actual (HTTP 409), p. ej. doble reserva. */
export class ConflictoError extends ErrorDominio {
  constructor(message: string) {
    super(message, 'CONFLICTO');
  }
}

/** Credenciales inválidas o token vencido (HTTP 401). */
export class NoAutenticadoError extends ErrorDominio {
  constructor(message = 'Credenciales inválidas') {
    super(message, 'NO_AUTENTICADO');
  }
}

export function asegurar(condicion: unknown, mensaje: string): asserts condicion {
  if (!condicion) throw new ReglaNegocioError(mensaje);
}
