import { PasarelaPayPalAdapter } from '../../src/modules/pagos/infrastructure/pasarela-paypal.adapter';

interface Llamada {
  metodo: string;
  ruta: string;
  headers: Record<string, string>;
  cuerpo?: Record<string, unknown>;
}

/** PayPal falso: responde según método + ruta y guarda cada llamada para revisarla. */
function paypalFalso(respuestas: Record<string, { status?: number; json?: unknown } | (() => { status?: number; json?: unknown })>) {
  const llamadas: Llamada[] = [];
  const fetch = async (url: string, init: { method?: string; headers?: Record<string, string>; body?: string } = {}) => {
    const ruta = url.replace('https://api-m.sandbox.paypal.com', '');
    const metodo = init.method ?? 'GET';
    llamadas.push({ metodo, ruta, headers: init.headers ?? {}, cuerpo: init.body && !ruta.includes('oauth2') ? JSON.parse(init.body) : undefined });
    if (ruta === '/v1/oauth2/token') return { ok: true, status: 200, text: async () => JSON.stringify({ access_token: 'TOKEN', expires_in: 32400 }) };
    const entrada = respuestas[`${metodo} ${ruta}`];
    const r = typeof entrada === 'function' ? entrada() : entrada;
    if (!r) return { ok: false, status: 404, text: async () => JSON.stringify({ name: 'RESOURCE_NOT_FOUND' }) };
    const status = r.status ?? 200;
    return { ok: status < 300, status, text: async () => (r.json === undefined ? '' : JSON.stringify(r.json)) };
  };
  const config = {
    get: (k: string) =>
      ({ PAYPAL_CLIENT_ID: 'cliente', PAYPAL_CLIENT_SECRET: 'secreto', PAYPAL_ENTORNO: 'sandbox', PUBLIC_API_URL: 'https://api.bewell.test/api/v1' })[k],
  };
  const adapter = new PasarelaPayPalAdapter(config as never, fetch);
  return { adapter, llamadas };
}

const ordenAutorizada = (auth = 'AUTH-1', status = 'CREATED') => ({
  id: 'ORD-1',
  status: 'COMPLETED',
  purchase_units: [{ payments: { authorizations: [{ id: auth, status }] } }],
});

describe('PasarelaPayPalAdapter (API REST v2, sandbox)', () => {
  it('crea una orden AUTHORIZE en USD con las URL de retorno de la API y devuelve el enlace de aprobación', async () => {
    const { adapter, llamadas } = paypalFalso({
      'POST /v2/checkout/orders': {
        status: 201,
        json: { id: 'ORD-1', status: 'PAYER_ACTION_REQUIRED', links: [{ rel: 'payer-action', href: 'https://www.sandbox.paypal.com/checkoutnow?token=ORD-1' }] },
      },
    });
    const orden = await adapter.crearOrden(4550, 'USD', 'cita123', 'cita:cita123');
    expect(orden).toEqual({ orden: 'ORD-1', urlAprobacion: 'https://www.sandbox.paypal.com/checkoutnow?token=ORD-1' });
    const crear = llamadas.find((l) => l.ruta === '/v2/checkout/orders')!;
    expect(crear.headers['PayPal-Request-Id']).toBe('cita:cita123');
    expect(crear.headers.Authorization).toBe('Bearer TOKEN');
    expect(crear.cuerpo).toMatchObject({
      intent: 'AUTHORIZE',
      purchase_units: [{ reference_id: 'cita123', amount: { currency_code: 'USD', value: '45.50' } }],
      payment_source: { paypal: { experience_context: { return_url: 'https://api.bewell.test/api/v1/pagos/paypal/retorno', cancel_url: 'https://api.bewell.test/api/v1/pagos/paypal/cancelado' } } },
    });
    expect(adapter.requiereAprobacion).toBe(true);
    expect(adapter.proveedor).toBe('PAYPAL');
  });

  it('autoriza la orden aprobada y devuelve la autorización (retención)', async () => {
    const { adapter } = paypalFalso({ 'POST /v2/checkout/orders/ORD-1/authorize': { status: 201, json: ordenAutorizada() } });
    expect(await adapter.autorizarOrden('ORD-1')).toMatchObject({ aprobado: true, referencia: 'AUTH-1' });
  });

  it('distingue "aún no aprobada" (pendiente) de un rechazo, y relee una orden ya autorizada', async () => {
    const noAprobada = paypalFalso({
      'POST /v2/checkout/orders/ORD-1/authorize': { status: 422, json: { name: 'UNPROCESSABLE_ENTITY', details: [{ issue: 'ORDER_NOT_APPROVED' }] } },
    });
    expect(await noAprobada.adapter.autorizarOrden('ORD-1')).toMatchObject({ aprobado: false, pendiente: true });

    const rechazada = paypalFalso({ 'POST /v2/checkout/orders/ORD-1/authorize': { status: 201, json: ordenAutorizada('AUTH-1', 'DENIED') } });
    expect(await rechazada.adapter.autorizarOrden('ORD-1')).toMatchObject({ aprobado: false });

    const repetida = paypalFalso({
      'POST /v2/checkout/orders/ORD-1/authorize': { status: 422, json: { details: [{ issue: 'ORDER_ALREADY_AUTHORIZED' }] } },
      'GET /v2/checkout/orders/ORD-1': { json: ordenAutorizada('AUTH-7') },
    });
    expect(await repetida.adapter.autorizarOrden('ORD-1')).toMatchObject({ aprobado: true, referencia: 'AUTH-7' });
  });

  it('captura el monto (final_capture) y trata una captura repetida como hecha', async () => {
    const { adapter, llamadas } = paypalFalso({ 'POST /v2/payments/authorizations/AUTH-1/capture': { status: 201, json: { id: 'CAP-1', status: 'COMPLETED' } } });
    expect(await adapter.capturar('AUTH-1', 2500, 'USD')).toMatchObject({ aprobado: true, referencia: 'CAP-1' });
    expect(llamadas.at(-1)!.cuerpo).toEqual({ amount: { currency_code: 'USD', value: '25.00' }, final_capture: true });

    const repetida = paypalFalso({
      'POST /v2/payments/authorizations/AUTH-1/capture': { status: 422, json: { details: [{ issue: 'AUTHORIZATION_ALREADY_CAPTURED' }] } },
    });
    expect((await repetida.adapter.capturar('AUTH-1', 2500)).aprobado).toBe(true);
  });

  it('reembolso total antes de capturar: anula la retención; parcial: no anula (se captura solo la penalización)', async () => {
    const total = paypalFalso({
      'GET /v2/payments/authorizations/AUTH-1': { json: { status: 'CREATED', amount: { value: '50.00' } } },
      'POST /v2/payments/authorizations/AUTH-1/void': { status: 204 },
    });
    expect((await total.adapter.reembolsar('AUTH-1', 5000, 'USD')).aprobado).toBe(true);
    expect(total.llamadas.some((l) => l.ruta.endsWith('/void'))).toBe(true);

    const parcial = paypalFalso({ 'GET /v2/payments/authorizations/AUTH-1': { json: { status: 'CREATED', amount: { value: '50.00' } } } });
    expect((await parcial.adapter.reembolsar('AUTH-1', 2500, 'USD')).aprobado).toBe(true);
    expect(parcial.llamadas.some((l) => l.ruta.endsWith('/void'))).toBe(false);
  });

  it('si ya se capturó, reembolsa la captura de la orden', async () => {
    const { adapter, llamadas } = paypalFalso({
      'GET /v2/payments/authorizations/AUTH-1': {
        json: { status: 'CAPTURED', amount: { value: '50.00' }, supplementary_data: { related_ids: { order_id: 'ORD-1' } } },
      },
      'GET /v2/checkout/orders/ORD-1': { json: { purchase_units: [{ payments: { captures: [{ id: 'CAP-1', status: 'COMPLETED' }] } }] } },
      'POST /v2/payments/captures/CAP-1/refund': { status: 201, json: { id: 'REF-1', status: 'COMPLETED' } },
    });
    expect(await adapter.reembolsar('AUTH-1', 5000, 'USD')).toMatchObject({ aprobado: true, referencia: 'REF-1' });
    expect(llamadas.at(-1)!.cuerpo).toEqual({ amount: { currency_code: 'USD', value: '50.00' } });
  });

  it('pide el token una sola vez y lo reutiliza', async () => {
    const { adapter, llamadas } = paypalFalso({ 'POST /v2/checkout/orders/ORD-1/authorize': { status: 201, json: ordenAutorizada() } });
    await adapter.autorizarOrden('ORD-1');
    await adapter.autorizarOrden('ORD-1');
    expect(llamadas.filter((l) => l.ruta === '/v1/oauth2/token')).toHaveLength(1);
  });

  it('sin credenciales no llama a PayPal y falla con un mensaje claro', async () => {
    const adapter = new PasarelaPayPalAdapter({ get: () => undefined } as never, async () => {
      throw new Error('no debería llamar');
    });
    await expect(adapter.crearOrden(1000, 'USD', 'c', 'k')).rejects.toThrow('credenciales de PayPal');
  });
});
