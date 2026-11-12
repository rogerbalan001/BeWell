/**
 * Variables de entorno de las pruebas e2e. Jest carga este archivo antes de
 * cada suite (setupFiles), así que AppModule ya las ve al importarse.
 */
const BASE_MONGO = process.env.MONGO_URI_E2E ?? 'mongodb://localhost:27017';
process.env.MONGO_URI = `${BASE_MONGO.replace(/\/$/, '')}/bewell_e2e_${Date.now()}`;
process.env.JWT_ACCESS_SECRET ??= 'e2e-acceso';
process.env.JWT_REFRESH_SECRET ??= 'e2e-refresh';
process.env.URL_SIGNING_SECRET ??= 'e2e-firma';
process.env.FIELD_ENCRYPTION_KEY ??= Buffer.alloc(32, 7).toString('base64');
process.env.KMS_MASTER_KEY ??= Buffer.alloc(32, 9).toString('base64');
process.env.STORAGE_DIR ??= `/tmp/bewell-e2e-${Date.now()}`;
process.env.PAGOS_PROVEEDOR = 'simulada';
process.env.IA_EXAMENES = 'simulado';
process.env.OCR_PROVIDER = 'simulado';

export {};
