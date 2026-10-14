import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';
import { esIdValido } from '../../domain/id';

/** Valida que un parámetro de ruta sea un identificador válido. */
@Injectable()
export class ParseObjectIdPipe implements PipeTransform<string, string> {
  transform(valor: string): string {
    if (!esIdValido(valor)) throw new BadRequestException(`Identificador inválido: ${valor}`);
    return valor;
  }
}
