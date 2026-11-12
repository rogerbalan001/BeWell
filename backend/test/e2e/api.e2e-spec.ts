/**
 * Pruebas de punta a punta por HTTP contra un MongoDB real: levantan la API
 * completa (AppModule), cargan los datos de demostración y recorren los
 * flujos principales como lo haría la app.
 *
 * Necesitan MongoDB. Localmente: `docker compose up -d mongo` y
 * `npm run test:e2e`. En GitHub Actions corren con un contenedor de MongoDB.
 * La base se crea con un nombre único y se borra al terminar. Las variables
 * de entorno se fijan en entorno-e2e.ts (setupFiles), antes de cargar AppModule.
 */
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { getConnectionToken } from '@nestjs/mongoose';
import { Test } from '@nestjs/testing';
import { Connection } from 'mongoose';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { sembrarDatosDemo } from '../../src/seed/datos-demo';

const CLAVE = 'Bewell2026!';

describe('API Bewell de punta a punta (HTTP + MongoDB)', () => {
  let app: INestApplication;
  let http: ReturnType<typeof request>;

  /** Inicia sesión por HTTP y devuelve el token de acceso. */
  async function entrar(email: string): Promise<string> {
    const r = await http.post('/api/v1/auth/login').send({ email, password: CLAVE }).expect(200);
    return r.body.accessToken as string;
  }

  beforeAll(async () => {
    const modulo = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = modulo.createNestApplication();
    // Igual que main.ts
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: false }));
    await app.init();
    await sembrarDatosDemo((token: unknown) => app.get(token as never), 'http://localhost:8080/#');
    http = request(app.getHttpServer());
  });

  afterAll(async () => {
    if (!app) return;
    await app.get<Connection>(getConnectionToken()).dropDatabase();
    await app.close();
  });

  it('responde la ruta de salud', async () => {
    await http.get('/api/v1/salud/vida').expect(200, { estado: 'ok' });
  });

  it('rechaza credenciales inválidas y rutas protegidas sin token', async () => {
    await http.post('/api/v1/auth/login').send({ email: 'sofia.morales@bewell.app', password: 'incorrecta' }).expect(401);
    await http.get('/api/v1/citas').expect(401);
  });

  it('valida los datos de entrada (400)', async () => {
    const token = await entrar('sofia.morales@bewell.app');
    await http.post('/api/v1/citas').set('Authorization', `Bearer ${token}`).send({ medicoId: 'no-es-un-id' }).expect(400);
  });

  it('un paciente agenda, el pago queda retenido y conversa con su médico por el chat', async () => {
    const sofia = await entrar('sofia.morales@bewell.app');
    const auth = { Authorization: `Bearer ${sofia}` };

    const perfiles = (await http.get('/api/v1/perfiles').set(auth).expect(200)).body as { id: string; esTitular: boolean }[];
    const titular = perfiles.find((p) => p.esTitular)!;
    const medicos = (await http.get('/api/v1/medicos').expect(200)).body as { id: string; nombreCompleto: string }[];
    const soto = medicos.find((m) => m.nombreCompleto.includes('Soto'))!;
    expect(soto).toBeDefined();

    const franjas = (await http.get('/api/v1/citas/disponibilidad').query({ medicoId: soto.id, dias: 14 }).expect(200)).body as { inicio: string }[];
    expect(franjas.length).toBeGreaterThan(0);
    const cita = (
      await http
        .post('/api/v1/citas')
        .set(auth)
        .send({ medicoId: soto.id, pacienteId: titular.id, inicio: franjas[franjas.length - 1].inicio, modalidad: 'VIRTUAL', motivo: 'Prueba e2e' })
        .expect(201)
    ).body as { id: string; estado: string; pago: { estado: string } };
    expect(cita.estado).toBe('CONFIRMADA');
    expect(cita.pago.estado).toBe('RETENIDO');

    // La misma franja no se puede reservar dos veces.
    await http
      .post('/api/v1/citas')
      .set(auth)
      .send({ medicoId: soto.id, pacienteId: titular.id, inicio: franjas[franjas.length - 1].inicio, modalidad: 'VIRTUAL' })
      .expect(409);

    // Chat privado de la cita.
    await http.post(`/api/v1/chat/citas/${cita.id}/mensajes`).set(auth).send({ texto: '¿Debo ir en ayunas?' }).expect(201);
    const drSoto = await entrar('valentina.soto@bewell.app');
    const noLeidos = (await http.get('/api/v1/chat/no-leidos').set('Authorization', `Bearer ${drSoto}`).expect(200)).body;
    expect(noLeidos.total).toBeGreaterThanOrEqual(1);
    const conversacion = (await http.get(`/api/v1/chat/citas/${cita.id}/mensajes`).set('Authorization', `Bearer ${drSoto}`).expect(200)).body;
    expect(conversacion.miParte).toBe('MEDICO');
    expect(conversacion.mensajes.map((m: { texto: string }) => m.texto)).toContain('¿Debo ir en ayunas?');

    // Un tercero no puede leer el chat.
    const martin = await entrar('martin.alvarez@bewell.app');
    await http.get(`/api/v1/chat/citas/${cita.id}/mensajes`).set('Authorization', `Bearer ${martin}`).expect(403);
  });

  it('las rutas del administrador rechazan a otros roles', async () => {
    const sofia = await entrar('sofia.morales@bewell.app');
    await http.get('/api/v1/pagos/disputas').set('Authorization', `Bearer ${sofia}`).expect(403);
    const admin = await entrar('admin@bewell.app');
    await http.get('/api/v1/pagos/disputas').set('Authorization', `Bearer ${admin}`).expect(200);
  });

  it('las descargas de archivos llevan X-Content-Type-Options: nosniff', async () => {
    const sofia = await entrar('sofia.morales@bewell.app');
    const auth = { Authorization: `Bearer ${sofia}` };
    const titular = ((await http.get('/api/v1/perfiles').set(auth)).body as { id: string; esTitular: boolean }[]).find((p) => p.esTitular)!;
    const examen = (
      await http
        .post('/api/v1/examenes')
        .set(auth)
        .field('pacienteId', titular.id)
        .field('titulo', 'Perfil lipídico')
        .attach('archivo', Buffer.from('%PDF-1.4\n% prueba e2e'), { filename: 'perfil.pdf', contentType: 'application/pdf' })
        .expect(201)
    ).body as { id: string };
    const { url } = (await http.get(`/api/v1/examenes/${examen.id}/archivo`).set(auth).expect(200)).body as { url: string };
    const ruta = new URL(url).pathname;
    const r = await http.get(ruta).expect(200);
    expect(r.headers['x-content-type-options']).toBe('nosniff');
  });
});
