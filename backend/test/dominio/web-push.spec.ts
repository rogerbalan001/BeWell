import { createECDH, createPublicKey, verify } from 'crypto';
import { rutaDeNotificacion } from '../../src/modules/notificaciones/domain/push';
import { cabeceraVapid, cifrarMensaje, generarClavesVapid } from '../../src/modules/notificaciones/infrastructure/web-push';

const b = (s: string) => Buffer.from(s, 'base64url');

describe('Notificaciones push (Web Push)', () => {
  it('cifra el mensaje igual que el ejemplo del RFC 8291', () => {
    const cuerpo = cifrarMensaje(
      Buffer.from('When I grow up, I want to be a watermelon'),
      { p256dh: 'BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4', auth: 'BTBZMqHH6r4Tts7J_aSIgg' },
      { servidorPrivada: b('yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw'), sal: b('DGv6ra1nlYgDCS1FRnbzlw') },
    );
    expect(cuerpo.toString('base64url')).toBe(
      'DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN',
    );
  });

  it('firma la cabecera VAPID con la clave del servidor para el origen del servicio push', () => {
    const claves = generarClavesVapid();
    const cabecera = cabeceraVapid('https://fcm.googleapis.com/fcm/send/abc', claves, 'mailto:soporte@bewell.app');
    const [token, k] = cabecera.replace('vapid t=', '').split(', k=');
    const [h, p, firma] = token.split('.');
    const publica = b(claves.publica);
    const clave = createPublicKey({
      key: { kty: 'EC', crv: 'P-256', x: publica.subarray(1, 33).toString('base64url'), y: publica.subarray(33).toString('base64url') },
      format: 'jwk',
    });
    expect(k).toBe(claves.publica);
    expect(verify('sha256', Buffer.from(`${h}.${p}`), { key: clave, dsaEncoding: 'ieee-p1363' }, b(firma))).toBe(true);
    expect(JSON.parse(b(p).toString()).aud).toBe('https://fcm.googleapis.com');
  });

  it('cada suscripción recibe un cuerpo distinto (sal y clave efímera nuevas)', () => {
    const navegador = createECDH('prime256v1');
    navegador.generateKeys();
    const s = { p256dh: navegador.getPublicKey().toString('base64url'), auth: Buffer.alloc(16, 7).toString('base64url') };
    expect(cifrarMensaje(Buffer.from('hola'), s).equals(cifrarMensaje(Buffer.from('hola'), s))).toBe(false);
  });

  it('al tocar la notificación se abre la pantalla relacionada', () => {
    expect(rutaDeNotificacion('RECORDATORIO', { tipo: 'MEDICAMENTOS' })).toBe('/recipes');
    expect(rutaDeNotificacion('RECORDATORIO', { tipo: 'EXAMENES' })).toBe('/examenes');
    expect(rutaDeNotificacion('RECORDATORIO', { citaId: 'c1' })).toBe('/citas/c1');
    expect(rutaDeNotificacion('CHAT', { citaId: 'c1' })).toBe('/citas/c1/chat');
    expect(rutaDeNotificacion('OTRA')).toBe('/notificaciones');
  });
});
