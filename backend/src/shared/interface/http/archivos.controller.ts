import { Controller, Get, Param, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { AlmacenamientoArchivos } from '../../application/almacenamiento-archivos';
import { Publico } from '../auth/decoradores';

/**
 * «Boundary» de lectura de archivos mediante URL firmada de corta duración.
 * El token ya autoriza la lectura, por eso el endpoint es público.
 */
@ApiTags('Archivos')
@Controller('archivos')
export class ArchivosController {
  constructor(private readonly almacenamiento: AlmacenamientoArchivos) {}

  @Publico()
  @Get(':token')
  async descargar(@Param('token') token: string, @Res() res: Response): Promise<void> {
    const ruta = this.almacenamiento.resolverTokenLectura(token);
    const archivo = await this.almacenamiento.leer(ruta);
    res.setHeader('Content-Type', archivo.tipoMime);
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(archivo.nombreOriginal)}"`);
    res.setHeader('Cache-Control', 'private, max-age=60');
    res.send(archivo.contenido);
  }
}
