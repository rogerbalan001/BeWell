import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import type { Response } from 'express';
import {
  AccesoDenegadoError,
  ConflictoError,
  ErrorDominio,
  NoAutenticadoError,
  NoEncontradoError,
} from '../../domain/errores';

/** Traduce errores de dominio a respuestas HTTP homogéneas. */
@Catch()
export class ErroresDominioFilter implements ExceptionFilter {
  private readonly logger = new Logger('API');

  catch(excepcion: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    if (excepcion instanceof HttpException) {
      const status = excepcion.getStatus();
      const cuerpo = excepcion.getResponse();
      res.status(status).json(typeof cuerpo === 'string' ? { statusCode: status, message: cuerpo } : cuerpo);
      return;
    }

    if (excepcion instanceof ErrorDominio) {
      const status =
        excepcion instanceof NoEncontradoError
          ? HttpStatus.NOT_FOUND
          : excepcion instanceof AccesoDenegadoError
            ? HttpStatus.FORBIDDEN
            : excepcion instanceof ConflictoError
              ? HttpStatus.CONFLICT
              : excepcion instanceof NoAutenticadoError
                ? HttpStatus.UNAUTHORIZED
                : HttpStatus.UNPROCESSABLE_ENTITY;
      res.status(status).json({ statusCode: status, codigo: excepcion.codigo, message: excepcion.message });
      return;
    }

    if ((excepcion as { code?: number })?.code === 11000) {
      res.status(HttpStatus.CONFLICT).json({
        statusCode: HttpStatus.CONFLICT,
        codigo: 'DUPLICADO',
        message: 'El recurso ya existe o la franja ya fue reservada',
      });
      return;
    }

    this.logger.error(excepcion instanceof Error ? excepcion.stack : String(excepcion));
    res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      message: 'Error interno del servidor',
    });
  }
}
