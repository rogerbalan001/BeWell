import { createCipheriv, createECDH, createHmac, createPrivateKey, generateKeyPairSync, randomBytes, sign } from 'crypto';

/**
 * Web Push sin dependencias externas: cifrado del mensaje (RFC 8291, aes128gcm)
 * e identificación del servidor con VAPID (RFC 8292). Lo usa el navegador del
 * teléfono para mostrar la notificación aunque la app esté cerrada.
 */

export interface ClavesVapid {
  /** Clave pública sin comprimir (65 bytes) en base64url: la usa el navegador para suscribirse. */
  publica: string;
  /** Escalar privado (32 bytes) en base64url. */
  privada: string;
}

export interface SuscripcionPush {
  endpoint: string;
  p256dh: string;
  auth: string;
}

const b64u = (b: Buffer): string => b.toString('base64url');
const desdeB64u = (s: string): Buffer => Buffer.from(s, 'base64url');
const hmac = (clave: Buffer, datos: Buffer): Buffer => createHmac('sha256', clave).update(datos).digest();

export function generarClavesVapid(): ClavesVapid {
  const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
  const jwk = privateKey.export({ format: 'jwk' });
  const publica = Buffer.concat([Buffer.from([4]), desdeB64u(jwk.x!), desdeB64u(jwk.y!)]);
  return { publica: b64u(publica), privada: jwk.d! };
}

/**
 * Cifra el contenido para una suscripción (RFC 8291). `servidor` y `sal` solo se
 * pasan en pruebas para reproducir los vectores del RFC.
 */
export function cifrarMensaje(
  contenido: Buffer,
  suscripcion: Pick<SuscripcionPush, 'p256dh' | 'auth'>,
  prueba?: { servidorPrivada: Buffer; sal: Buffer },
): Buffer {
  const clientePublicaBin = desdeB64u(suscripcion.p256dh);
  const secretoAuth = desdeB64u(suscripcion.auth);
  const ecdh = createECDH('prime256v1');
  if (prueba) ecdh.setPrivateKey(prueba.servidorPrivada);
  else ecdh.generateKeys();
  const servidorPublica = ecdh.getPublicKey();
  const compartido = ecdh.computeSecret(clientePublicaBin);

  const prkClave = hmac(secretoAuth, compartido);
  const infoClave = Buffer.concat([Buffer.from('WebPush: info\0'), clientePublicaBin, servidorPublica, Buffer.from([1])]);
  const ikm = hmac(prkClave, infoClave);

  const sal = prueba?.sal ?? randomBytes(16);
  const prk = hmac(sal, ikm);
  const cek = hmac(prk, Buffer.from('Content-Encoding: aes128gcm\0\x01', 'binary')).subarray(0, 16);
  const nonce = hmac(prk, Buffer.from('Content-Encoding: nonce\0\x01', 'binary')).subarray(0, 12);

  const cifrador = createCipheriv('aes-128-gcm', cek, nonce);
  const cifrado = Buffer.concat([cifrador.update(Buffer.concat([contenido, Buffer.from([2])])), cifrador.final(), cifrador.getAuthTag()]);

  const tamanoRegistro = Buffer.alloc(4);
  tamanoRegistro.writeUInt32BE(4096);
  return Buffer.concat([sal, tamanoRegistro, Buffer.from([servidorPublica.length]), servidorPublica, cifrado]);
}

/** Cabecera Authorization de VAPID: un JWT ES256 firmado para el origen del servicio push. */
export function cabeceraVapid(endpoint: string, claves: ClavesVapid, contacto: string, ahora = new Date()): string {
  const publica = desdeB64u(claves.publica);
  const clave = createPrivateKey({
    key: { kty: 'EC', crv: 'P-256', d: claves.privada, x: b64u(publica.subarray(1, 33)), y: b64u(publica.subarray(33, 65)) },
    format: 'jwk',
  });
  const cabecera = b64u(Buffer.from(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const cuerpo = b64u(
    Buffer.from(JSON.stringify({ aud: new URL(endpoint).origin, exp: Math.floor(ahora.getTime() / 1000) + 12 * 3600, sub: contacto })),
  );
  const firma = sign('sha256', Buffer.from(`${cabecera}.${cuerpo}`), { key: clave, dsaEncoding: 'ieee-p1363' });
  return `vapid t=${cabecera}.${cuerpo}.${b64u(firma)}, k=${claves.publica}`;
}

/** Envía un mensaje push. Devuelve el código HTTP del servicio (201 = aceptado; 404/410 = suscripción vencida). */
export async function enviarPush(
  suscripcion: SuscripcionPush,
  contenido: object,
  claves: ClavesVapid,
  contacto: string,
): Promise<number> {
  const cuerpo = cifrarMensaje(Buffer.from(JSON.stringify(contenido)), suscripcion);
  const respuesta = await fetch(suscripcion.endpoint, {
    method: 'POST',
    headers: {
      'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream',
      TTL: '86400',
      Urgency: 'normal',
      Authorization: cabeceraVapid(suscripcion.endpoint, claves, contacto),
    },
    body: new Uint8Array(cuerpo),
  });
  return respuesta.status;
}
