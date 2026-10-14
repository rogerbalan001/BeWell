/* Crea backend/.env a partir de .env.example con llaves criptográficas aleatorias. */
const { randomBytes } = require('crypto');
const { existsSync, readFileSync, writeFileSync } = require('fs');
const { join } = require('path');

const destino = join(__dirname, '..', '.env');
if (existsSync(destino)) {
  console.log('.env ya existe; no se modificó.');
  process.exit(0);
}
const b64 = () => randomBytes(32).toString('base64');
const texto = readFileSync(join(__dirname, '..', '.env.example'), 'utf8')
  .replace('FIELD_ENCRYPTION_KEY=REEMPLAZAR_CON_32_BYTES_BASE64', `FIELD_ENCRYPTION_KEY=${b64()}`)
  .replace('KMS_MASTER_KEY=REEMPLAZAR_CON_32_BYTES_BASE64', `KMS_MASTER_KEY=${b64()}`)
  .replace('JWT_ACCESS_SECRET=cambia-esto-access', `JWT_ACCESS_SECRET=${b64()}`)
  .replace('JWT_REFRESH_SECRET=cambia-esto-refresh', `JWT_REFRESH_SECRET=${b64()}`)
  .replace('URL_SIGNING_SECRET=cambia-esto-url', `URL_SIGNING_SECRET=${b64()}`);
writeFileSync(destino, texto);
console.log('✔ backend/.env creado con llaves aleatorias.');
