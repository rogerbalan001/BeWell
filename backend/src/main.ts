import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { getConnectionToken } from '@nestjs/mongoose';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Connection } from 'mongoose';
import { AppModule } from './app.module';
import { sembrarDatosDemo } from './seed/datos-demo';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api/v1');
  const origenes = process.env.CORS_ORIGIN ?? '*';
  app.enableCors({ origin: origenes === '*' ? true : origenes.split(',').map((o) => o.trim()), credentials: false });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: false }));
  app.enableShutdownHooks();

  const openapi = new DocumentBuilder()
    .setTitle('Bewell API')
    .setDescription('Plataforma e-Health · MVP Sprint 1 (NestJS + MongoDB)')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('api/docs', app, SwaggerModule.createDocument(app, openapi));

  const puerto = Number(process.env.PORT ?? 3000);
  await app.listen(puerto, '0.0.0.0');
  Logger.log(`API lista en http://localhost:${puerto}/api/v1  ·  OpenAPI en /api/docs`, 'Bewell');

  // Entorno de demostración: si la base de datos está vacía, carga los datos de demo.
  if (process.env.SEED_SI_VACIA === 'true') {
    const conexion = app.get<Connection>(getConnectionToken());
    const usuarios = await conexion.collection('usuarios').countDocuments();
    if (usuarios === 0) {
      Logger.log('Base de datos vacía: cargando datos de demostración…', 'Bewell');
      const r = await sembrarDatosDemo((token: unknown) => app.get(token as never), process.env.PUBLIC_WEB_URL ?? 'http://localhost:8080/#');
      Logger.log(`Datos de demo listos. Récipe: ${r.codigoRecipe} · QR: ${r.urlQrEmergencia}`, 'Bewell');
    }
  }
}

void bootstrap();
