#!/usr/bin/env node
/**
 * Mide la latencia de la ficha de emergencia (GET /emergencia/qr/:token) y
 * calcula p50, p95 y p99. Meta del documento: p95 < 200 ms.
 *
 * Uso:
 *   node scripts/medir-p95-qr.js <enlace-del-QR | token> [api] [muestras]
 *   node scripts/medir-p95-qr.js https://bewell-app.onrender.com/#/e/abc123
 *   node scripts/medir-p95-qr.js abc123 https://bewell-api.onrender.com/api/v1 25
 *
 * - El enlace se copia de la pantalla "Mi QR" de la app (o se escanea el QR).
 * - La ruta tiene un límite de 30 peticiones por minuto por IP, así que las
 *   muestras se espacian ~2,1 s para no recibir 429.
 * - La primera petición calienta el servidor (Render gratis se duerme) y no cuenta.
 * - Lo medido incluye la red entre tu equipo y Render: es una cota superior del
 *   tiempo del servidor. Anota de dónde mediste.
 */
const [, , entrada, apiArg, muestrasArg] = process.argv;
if (!entrada) {
  console.error('Falta el enlace del QR o su token. Ejemplo: node scripts/medir-p95-qr.js https://bewell-app.onrender.com/#/e/abc123');
  process.exit(1);
}
const token = entrada.includes('/e/') ? entrada.split('/e/').pop().split(/[?#]/)[0] : entrada;
const api = (apiArg || process.env.API_URL || 'https://bewell-api.onrender.com/api/v1').replace(/\/$/, '');
const muestras = Math.min(Math.max(parseInt(muestrasArg || '25', 10), 5), 29);
const ESPERA_MS = 2100;

const percentil = (ordenados, p) => ordenados[Math.min(ordenados.length - 1, Math.ceil((p / 100) * ordenados.length) - 1)];
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));

async function medirUna() {
  const inicio = performance.now();
  const r = await fetch(`${api}/emergencia/qr/${encodeURIComponent(token)}`, { headers: { Accept: 'application/json' } });
  await r.text();
  return { ms: performance.now() - inicio, status: r.status };
}

(async () => {
  console.log(`API: ${api}\nMuestras: ${muestras} (más 1 de calentamiento)\n`);
  const calentamiento = await medirUna();
  if (calentamiento.status !== 200) {
    console.error(`La ficha respondió ${calentamiento.status}. Revisa que el enlace del QR sea vigente (regenerarlo invalida el anterior).`);
    process.exit(1);
  }
  console.log(`Calentamiento: ${calentamiento.ms.toFixed(0)} ms (no cuenta)`);
  const tiempos = [];
  for (let i = 0; i < muestras; i++) {
    await dormir(ESPERA_MS);
    const { ms, status } = await medirUna();
    if (status !== 200) {
      console.error(`Muestra ${i + 1}: HTTP ${status}; se descarta.`);
      continue;
    }
    tiempos.push(ms);
    process.stdout.write(`.${(i + 1) % 10 === 0 ? ` ${i + 1}\n` : ''}`);
  }
  const t = [...tiempos].sort((a, b) => a - b);
  const p95 = percentil(t, 95);
  console.log(`\n\nMuestras válidas: ${t.length}`);
  console.log(`mín ${t[0].toFixed(0)} ms · p50 ${percentil(t, 50).toFixed(0)} ms · p95 ${p95.toFixed(0)} ms · p99 ${percentil(t, 99).toFixed(0)} ms · máx ${t[t.length - 1].toFixed(0)} ms`);
  console.log(p95 < 200 ? 'Cumple la meta: p95 < 200 ms.' : 'No cumple la meta de p95 < 200 ms (recuerda que incluye la latencia de red).');
  console.log(`Fecha: ${new Date().toISOString()}`);
})().catch((e) => {
  console.error(`Error: ${e.message}`);
  process.exit(1);
});
