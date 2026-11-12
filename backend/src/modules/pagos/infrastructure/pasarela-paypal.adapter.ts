import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Centavos } from '../../../shared/domain/dinero';
import { OrdenPasarela, PasarelaPagos, ResultadoPasarela } from '../application/pasarela-pagos';

export const PROVEEDOR_PAYPAL = 'PAYPAL';

const URL_API = {
  sandbox: 'https://api-m.sandbox.paypal.com',
  live: 'https://api-m.paypal.com',
} as const;

type Fetch = (url: string, init?: { method?: string; headers?: Record<string, string>; body?: string }) => Promise<{
  ok: boolean;
  status: number;
  text(): Promise<string>;
}>;

interface ErrorPayPal {
  name?: string;
  message?: string;
  debug_id?: string;
  details?: { issue?: string; description?: string }[];
}

/** Error de la API de PayPal con el código del problema (`issue`) para decidir qué hacer. */
export class PayPalApiError extends Error {
  constructor(
    readonly status: number,
    readonly issue: string | undefined,
    message: string,
    readonly debugId?: string,
  ) {
    super(message);
    this.name = 'PayPalApiError';
  }
}

const aValor = (monto: Centavos) => (monto / 100).toFixed(2);
const deValor = (valor: string | undefined) => Math.round(parseFloat(valor ?? '0') * 100);

/**
 * Adapter de PayPal (API REST v2, entorno sandbox por defecto) con pago retenido:
 * 1. `crearOrden`: orden con intent AUTHORIZE; el paciente la aprueba en PayPal.
 * 2. `autorizarOrden`: al volver, se autoriza la orden y el monto queda retenido.
 * 3. `capturar`: 24 h después de la consulta se cobra la retención (o la parte que
 *    le toca al médico si hubo penalización); el resto se libera solo.
 * 4. `reembolsar`: si se cancela antes de capturar, se anula la retención; si ya
 *    se había capturado, se reembolsa la captura.
 * Variables: PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, PAYPAL_ENTORNO (sandbox|live),
 * PUBLIC_API_URL (para las URL de retorno). Se crea en `PagosModule` según PAGOS_PROVEEDOR.
 */
export class PasarelaPayPalAdapter extends PasarelaPagos {
  private readonly logger = new Logger('PasarelaPayPal');
  private readonly base: string;
  private readonly clientId: string;
  private readonly secreto: string;
  private readonly urlApi: string;
  private token?: { valor: string; venceEn: number };
  private readonly fetch: Fetch;

  constructor(config: ConfigService, fetchFn?: Fetch) {
    super();
    const entorno = (config.get<string>('PAYPAL_ENTORNO') ?? 'sandbox').toLowerCase() === 'live' ? 'live' : 'sandbox';
    this.base = URL_API[entorno];
    this.clientId = config.get<string>('PAYPAL_CLIENT_ID') ?? '';
    this.secreto = config.get<string>('PAYPAL_CLIENT_SECRET') ?? '';
    this.urlApi = (config.get<string>('PUBLIC_API_URL') ?? 'http://localhost:3000/api/v1').replace(/\/$/, '');
    this.fetch = fetchFn ?? (globalThis.fetch as unknown as Fetch);
    if (!this.clientId || !this.secreto) {
      this.logger.warn('PAGOS_PROVEEDOR=paypal pero faltan PAYPAL_CLIENT_ID o PAYPAL_CLIENT_SECRET: los cobros fallarán.');
    }
  }

  override get proveedor(): string {
    return PROVEEDOR_PAYPAL;
  }

  override get requiereAprobacion(): boolean {
    return true;
  }

  /** PayPal siempre necesita que el paciente apruebe el pago: se usa `crearOrden`. */
  async autorizar(): Promise<ResultadoPasarela> {
    return { aprobado: false, mensaje: 'PayPal requiere que el paciente apruebe el pago' };
  }

  override async crearOrden(monto: Centavos, moneda: string, referenciaInterna: string, claveIdempotencia: string): Promise<OrdenPasarela> {
    const orden = await this.llamar<{ id: string; links?: { rel: string; href: string }[] }>('POST', '/v2/checkout/orders', {
      idempotencia: claveIdempotencia,
      cuerpo: {
        intent: 'AUTHORIZE',
        purchase_units: [
          {
            reference_id: referenciaInterna,
            custom_id: referenciaInterna,
            description: 'Consulta médica en Bewell',
            amount: { currency_code: moneda, value: aValor(monto) },
          },
        ],
        payment_source: {
          paypal: {
            experience_context: {
              brand_name: 'Bewell',
              locale: 'es-ES',
              shipping_preference: 'NO_SHIPPING',
              user_action: 'PAY_NOW',
              return_url: `${this.urlApi}/pagos/paypal/retorno`,
              cancel_url: `${this.urlApi}/pagos/paypal/cancelado`,
            },
          },
        },
      },
    });
    const url = orden.links?.find((l) => l.rel === 'payer-action' || l.rel === 'approve')?.href;
    if (!url) throw new Error(`PayPal no devolvió el enlace de aprobación de la orden ${orden.id}`);
    this.logger.log(`Orden ${orden.id}: ${aValor(monto)} ${moneda} (cita ${referenciaInterna})`);
    return { orden: orden.id, urlAprobacion: url };
  }

  override async autorizarOrden(orden: string): Promise<ResultadoPasarela> {
    try {
      const r = await this.llamar<OrdenConPagos>('POST', `/v2/checkout/orders/${orden}/authorize`, { idempotencia: `${orden}-autorizar`, cuerpo: {} });
      return this.resultadoAutorizacion(r);
    } catch (e) {
      if (!(e instanceof PayPalApiError)) throw e;
      if (e.issue === 'ORDER_NOT_APPROVED' || e.issue === 'PAYER_ACTION_REQUIRED') {
        return { aprobado: false, pendiente: true, mensaje: 'El paciente aún no aprueba el pago en PayPal' };
      }
      if (e.issue === 'ORDER_ALREADY_AUTHORIZED') {
        return this.resultadoAutorizacion(await this.llamar<OrdenConPagos>('GET', `/v2/checkout/orders/${orden}`));
      }
      if (e.status === 404 || e.status === 422) return { aprobado: false, mensaje: `PayPal rechazó el pago (${e.issue ?? e.message})` };
      throw e;
    }
  }

  async capturar(autorizacion: string, monto: Centavos, moneda = 'USD'): Promise<ResultadoPasarela> {
    try {
      const r = await this.llamar<{ id: string; status: string }>('POST', `/v2/payments/authorizations/${autorizacion}/capture`, {
        idempotencia: `${autorizacion}-capturar`,
        cuerpo: { amount: { currency_code: moneda, value: aValor(monto) }, final_capture: true },
      });
      const aprobado = r.status === 'COMPLETED' || r.status === 'PENDING';
      return { aprobado, referencia: r.id, mensaje: aprobado ? 'Cobro capturado en PayPal' : `Captura ${r.status}` };
    } catch (e) {
      if (e instanceof PayPalApiError && e.issue === 'AUTHORIZATION_ALREADY_CAPTURED') return { aprobado: true, referencia: autorizacion };
      return this.fallo(e, 'capturar');
    }
  }

  async reembolsar(autorizacion: string, monto: Centavos, moneda = 'USD'): Promise<ResultadoPasarela> {
    try {
      const auth = await this.llamar<{
        status: string;
        amount?: { value: string };
        supplementary_data?: { related_ids?: { order_id?: string } };
      }>('GET', `/v2/payments/authorizations/${autorizacion}`);

      if (auth.status === 'VOIDED' || auth.status === 'EXPIRED') return { aprobado: true, referencia: autorizacion, mensaje: 'La retención ya no estaba activa' };

      if (auth.status === 'CREATED' || auth.status === 'PENDING') {
        // Aún no se cobró: anular devuelve todo. Si es parcial, la captura del resto
        // (con final_capture) libera automáticamente lo que no se cobra.
        if (monto < deValor(auth.amount?.value)) return { aprobado: true, referencia: autorizacion, mensaje: 'Se cobrará solo la penalización' };
        await this.llamar('POST', `/v2/payments/authorizations/${autorizacion}/void`, { idempotencia: `${autorizacion}-anular` });
        return { aprobado: true, referencia: autorizacion, mensaje: 'Retención anulada en PayPal' };
      }

      // Ya capturado: se reembolsa la captura de la orden.
      const ordenId = auth.supplementary_data?.related_ids?.order_id;
      if (!ordenId) return { aprobado: false, mensaje: `No se encontró la orden de la autorización (${auth.status})` };
      const orden = await this.llamar<OrdenConPagos>('GET', `/v2/checkout/orders/${ordenId}`);
      const captura = orden.purchase_units?.[0]?.payments?.captures?.find((c) => c.status === 'COMPLETED' || c.status === 'PARTIALLY_REFUNDED');
      if (!captura) return { aprobado: false, mensaje: 'No hay una captura que reembolsar' };
      const r = await this.llamar<{ id: string; status: string }>('POST', `/v2/payments/captures/${captura.id}/refund`, {
        idempotencia: `${captura.id}-reembolso-${monto}`,
        cuerpo: { amount: { currency_code: moneda, value: aValor(monto) } },
      });
      return { aprobado: r.status === 'COMPLETED' || r.status === 'PENDING', referencia: r.id, mensaje: 'Reembolso enviado por PayPal' };
    } catch (e) {
      return this.fallo(e, 'reembolsar');
    }
  }

  // ---------- HTTP ----------

  private resultadoAutorizacion(orden: OrdenConPagos): ResultadoPasarela {
    const auth = orden.purchase_units?.[0]?.payments?.authorizations?.[0];
    if (!auth) return { aprobado: false, mensaje: `La orden quedó ${orden.status} sin autorización` };
    if (auth.status === 'CREATED' || auth.status === 'PENDING' || auth.status === 'CAPTURED') {
      return { aprobado: true, referencia: auth.id, mensaje: `Pago aprobado en PayPal y retenido (autorización ${auth.id})` };
    }
    return { aprobado: false, mensaje: `PayPal no autorizó el pago (${auth.status})` };
  }

  private fallo(e: unknown, accion: string): ResultadoPasarela {
    const msg = e instanceof PayPalApiError ? `${e.issue ?? e.status}: ${e.message}` : (e as Error).message;
    this.logger.error(`No se pudo ${accion} en PayPal: ${msg}`);
    return { aprobado: false, mensaje: msg };
  }

  private async obtenerToken(): Promise<string> {
    if (this.token && this.token.venceEn > Date.now()) return this.token.valor;
    if (!this.clientId || !this.secreto) throw new Error('Faltan las credenciales de PayPal (PAYPAL_CLIENT_ID y PAYPAL_CLIENT_SECRET)');
    const r = await this.fetch(`${this.base}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${this.clientId}:${this.secreto}`).toString('base64')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    });
    const texto = await r.text();
    if (!r.ok) throw new PayPalApiError(r.status, 'AUTENTICACION', `PayPal rechazó las credenciales (${r.status})`);
    const datos = JSON.parse(texto) as { access_token: string; expires_in: number };
    this.token = { valor: datos.access_token, venceEn: Date.now() + Math.max(datos.expires_in - 60, 30) * 1000 };
    return this.token.valor;
  }

  private async llamar<T = unknown>(metodo: 'GET' | 'POST', ruta: string, opciones: { cuerpo?: unknown; idempotencia?: string } = {}): Promise<T> {
    const headers: Record<string, string> = {
      Authorization: `Bearer ${await this.obtenerToken()}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    };
    if (opciones.idempotencia) headers['PayPal-Request-Id'] = opciones.idempotencia;
    const r = await this.fetch(`${this.base}${ruta}`, {
      method: metodo,
      headers,
      body: opciones.cuerpo === undefined ? undefined : JSON.stringify(opciones.cuerpo),
    });
    const texto = await r.text();
    if (!r.ok) {
      let err: ErrorPayPal = {};
      try {
        err = JSON.parse(texto) as ErrorPayPal;
      } catch {
        /* respuesta sin JSON */
      }
      const issue = err.details?.[0]?.issue ?? err.name;
      const detalle = err.details?.[0]?.description ?? err.message ?? `HTTP ${r.status}`;
      this.logger.warn(`PayPal ${metodo} ${ruta} → ${r.status} ${issue ?? ''} (debug_id ${err.debug_id ?? '-'})`);
      throw new PayPalApiError(r.status, issue, detalle, err.debug_id);
    }
    return (texto ? JSON.parse(texto) : {}) as T;
  }
}

interface OrdenConPagos {
  id?: string;
  status?: string;
  purchase_units?: {
    payments?: {
      authorizations?: { id: string; status: string }[];
      captures?: { id: string; status: string }[];
    };
  }[];
}
