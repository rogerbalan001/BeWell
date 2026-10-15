import { NoEncontradoError, ReglaNegocioError } from '../../src/shared/domain/errores';
import { RolUsuario } from '../../src/shared/domain/roles';
import { canonicalizar } from '../../src/modules/recipes/application/firma-digital.service';
import { crearContexto } from '../support/contexto';

const NUEVE_AM = new Date('2026-10-12T13:00:00.000Z');
const ITEMS = [{ medicamento: 'Loratadina', presentacion: 'Tab 10 mg', dosis: '1 tab', frecuencia: 'cada 24 h', duracionDias: 14 }];

describe('Firma digital (JCS RFC 8785 + ECDSA P-256)', () => {
  it('canonicaliza ordenando claves en todos los niveles', () => {
    expect(canonicalizar({ b: 1, a: { d: [3, { z: 1, y: 2 }], c: 'x' } })).toBe('{"a":{"c":"x","d":[3,{"y":2,"z":1}]},"b":1}');
  });

  it('firma y verifica; cualquier alteración invalida la firma', async () => {
    const ctx = crearContexto();
    const llave = await ctx.kms.crearLlaveFirma();
    const contenido = { codigo: 'RX-1', items: ITEMS };
    const { firma } = await ctx.firma.firmar(llave, contenido);
    expect((await ctx.firma.verificar(contenido, firma, llave)).firmaValida).toBe(true);
    expect((await ctx.firma.verificar({ ...contenido, codigo: 'RX-2' }, firma, llave)).firmaValida).toBe(false);
  });
});

describe('RecipesService (HU: récipes digitales con firma y código verificable)', () => {
  async function consultaAtendida() {
    const ctx = crearContexto();
    const medico = await ctx.medicoVerificado('Mateo');
    const { actor, perfil } = await ctx.pacienteTitular();
    const cita = await ctx.citas.agendar(actor, { medicoId: medico.medicoId!, pacienteId: perfil.id, inicio: NUEVE_AM, modalidad: 'PRESENCIAL', motivo: '' });
    return { ctx, medico, actor, perfil, cita };
  }

  it('solo se emite para consultas atendidas', async () => {
    const { ctx, medico, cita } = await consultaAtendida();
    await expect(ctx.recipes.emitir(medico, cita.id, { items: ITEMS })).rejects.toThrow(ReglaNegocioError);
  });

  it('una farmacia verifica el récipe; al anularlo deja de ser válido', async () => {
    const { ctx, medico, actor, perfil, cita } = await consultaAtendida();
    ctx.reloj.avanzarHoras(1);
    await ctx.citas.marcarAtendida(medico, cita.id, {});
    const recipe = await ctx.recipes.emitir(medico, cita.id, { items: ITEMS, diagnostico: 'Rinitis' });
    expect(recipe.codigoVerificacion).toMatch(/^RX-[A-Z2-9]{5}-[A-Z2-9]{5}$/);

    const v = await ctx.recipes.verificar(recipe.codigoVerificacion.toLowerCase());
    expect(v.valido).toBe(true);
    expect(v.integro).toBe(true);

    // Se guarda automáticamente en el expediente del paciente.
    const linea = await ctx.expediente.obtenerLineaDeTiempo(actor, perfil.id, {});
    expect(linea.items.some((e) => e.documentoOrigenId === recipe.id)).toBe(true);

    await ctx.recipes.anular(medico, recipe.id, 'Error en la dosis');
    const anulado = await ctx.recipes.verificar(recipe.codigoVerificacion);
    expect(anulado.valido).toBe(false);
    expect(anulado.firmaValida).toBe(true);
  });

  it('un código inexistente no es válido', async () => {
    const ctx = crearContexto();
    expect((await ctx.recipes.verificar('RX-NOPE')).encontrado).toBe(false);
  });
});

describe('EmergenciaService (HU: QR de emergencia sin iniciar sesión)', () => {
  async function fichaConQr() {
    const ctx = crearContexto();
    const { actor, perfil } = await ctx.pacienteTitular();
    await ctx.emergencia.actualizarFicha(actor, perfil.id, {
      grupoSanguineo: 'A+',
      alergias: ['Penicilina'],
      condicionesCronicas: ['Diabetes tipo 1'],
      medicacionActual: ['Insulina glargina'],
      contactos: [{ nombre: 'Carlos', parentesco: 'Esposo', telefono: '+58 414 000' }],
      camposPublicos: ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'contactos'],
    });
    const qr = await ctx.emergencia.regenerarQr(actor, perfil.id);
    return { ctx, actor, perfil, qr };
  }

  it('el acceso público muestra solo la ficha mínima y queda auditado', async () => {
    const { ctx, qr } = await fichaConQr();
    expect(qr.url).toBe(`https://app.test/#/e/${qr.token}`);
    const r = await ctx.emergencia.obtenerFichaPorToken(qr.token, undefined);
    expect(r.ficha.nivel).toBe('PUBLICO');
    expect(r.ficha.alergias).toEqual(['Penicilina']);
    expect(r.ficha.medicacionActual).toBeUndefined();
    await new Promise((ok) => setTimeout(ok, 0));
    expect(ctx.auditoria.entradas[0].accesoEmergencia).toBe(true);
  });

  it('el personal de emergencia autenticado ve la ficha ampliada', async () => {
    const { ctx, qr } = await fichaConQr();
    const r = await ctx.emergencia.obtenerFichaPorToken(qr.token, { id: 'e'.repeat(24), email: 'e@t', roles: [RolUsuario.PERSONAL_EMERGENCIA] });
    expect(r.ficha.nivel).toBe('AMPLIADO');
    expect(r.ficha.medicacionActual).toEqual(['Insulina glargina']);
  });

  it('usa la caché y regenerar el QR invalida el token anterior', async () => {
    const { ctx, actor, perfil, qr } = await fichaConQr();
    await ctx.emergencia.obtenerFichaPorToken(qr.token, undefined);
    expect(ctx.cache.datos.size).toBe(1);
    await ctx.emergencia.regenerarQr(actor, perfil.id);
    expect(ctx.cache.datos.size).toBe(0);
    await expect(ctx.emergencia.obtenerFichaPorToken(qr.token, undefined)).rejects.toThrow(NoEncontradoError);
  });

  it('editar la ficha invalida la caché', async () => {
    const { ctx, actor, perfil, qr } = await fichaConQr();
    await ctx.emergencia.obtenerFichaPorToken(qr.token, undefined);
    const ficha = await ctx.emergencia.obtenerFicha(actor, perfil.id);
    await ctx.emergencia.actualizarFicha(actor, perfil.id, { ...ficha, alergias: ['Penicilina', 'Látex'] });
    const r = await ctx.emergencia.obtenerFichaPorToken(qr.token, undefined);
    expect(r.ficha.alergias).toEqual(['Penicilina', 'Látex']);
  });
});
