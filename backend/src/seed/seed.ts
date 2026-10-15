/* eslint-disable no-console */
/** Uso: `npm run seed` — BORRA la base de datos de MONGO_URI y carga los datos de demostración. */
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { sembrarDatosDemo } from './datos-demo';

async function main(): Promise<void> {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error', 'warn'] });
  console.log('→ Limpiando la base de datos y cargando datos de demostración…');
  const r = await sembrarDatosDemo((token: unknown) => app.get(token as never), process.env.PUBLIC_WEB_URL ?? 'http://localhost:8080/#');
  console.log('\n✔ Datos de demostración creados. Contraseña de todas las cuentas: %s\n', r.password);
  console.table(r.cuentas);
  console.log(`Récipe para verificar en farmacia: ${r.codigoRecipe}`);
  console.log(`QR de emergencia de Sofía: ${r.urlQrEmergencia}\n`);
  await app.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
