/**
 * Adaptadores en memoria de los puertos «Repository» y de los servicios
 * externos. Gracias a la arquitectura hexagonal, los casos de uso se prueban
 * sin MongoDB, Redis ni pasarela de pagos.
 */
import { createHash, createHmac, generateKeyPairSync, KeyObject, sign } from 'crypto';
import { AlmacenamientoArchivos, ArchivoGuardado, ArchivoLeido } from '../../src/shared/application/almacenamiento-archivos';
import { CifradorCampos } from '../../src/shared/application/cifrador-campos';
import { NuevaNotificacion, Notificador } from '../../src/shared/application/notificador';
import { EntradaAuditoria, RegistroAuditoria } from '../../src/shared/application/registro-auditoria';
import { generarId } from '../../src/shared/domain/id';
import { Reloj } from '../../src/shared/domain/reloj';
import { Cita, EstadoCita } from '../../src/modules/citas/domain/cita';
import { CitaRepository, FiltrosCitas } from '../../src/modules/citas/domain/cita.repository';
import { FichaCacheada, FichaEmergenciaCache } from '../../src/modules/emergencias/application/ficha-emergencia.cache';
import { FichaEmergencia, FichaEmergenciaRepository } from '../../src/modules/emergencias/domain/ficha-emergencia';
import { CategoriaClinica, TipoEvento } from '../../src/modules/expediente/domain/categoria-clinica';
import { EventoClinico } from '../../src/modules/expediente/domain/evento-clinico';
import { ExpedienteClinico } from '../../src/modules/expediente/domain/expediente-clinico';
import { PermisoAcceso } from '../../src/modules/expediente/domain/permiso-acceso';
import { ReferenciaEspecialista } from '../../src/modules/expediente/domain/referencia-especialista';
import {
  EventoClinicoRepository,
  ExpedienteRepository,
  Paginacion,
  PermisoAccesoRepository,
  ReferenciaRepository,
} from '../../src/modules/expediente/domain/repositorios';
import { EstadoVerificacion } from '../../src/modules/medicos/domain/credencial-profesional';
import { Medico } from '../../src/modules/medicos/domain/medico';
import { FiltrosDirectorio, MedicoRepository } from '../../src/modules/medicos/domain/medico.repository';
import { PasarelaPagos, ResultadoPasarela } from '../../src/modules/pagos/application/pasarela-pagos';
import { EstadoPago, Pago } from '../../src/modules/pagos/domain/pago';
import { PagoRepository } from '../../src/modules/pagos/domain/pago.repository';
import { PerfilPaciente } from '../../src/modules/perfiles/domain/perfil-paciente';
import { PerfilPacienteRepository } from '../../src/modules/perfiles/domain/perfil-paciente.repository';
import { Kms } from '../../src/modules/recipes/application/kms';

export class RelojFijo extends Reloj {
  constructor(public fecha: Date) {
    super();
  }
  ahora(): Date {
    return new Date(this.fecha);
  }
  avanzarHoras(horas: number): void {
    this.fecha = new Date(this.fecha.getTime() + horas * 3_600_000);
  }
}

/** Copia profunda que conserva prototipos: simula la persistencia sin compartir referencias con el dominio. */
function clonarProfundo(v: unknown): unknown {
  if (v instanceof Date) return new Date(v.getTime());
  if (Buffer.isBuffer(v)) return Buffer.from(v);
  if (Array.isArray(v)) return v.map(clonarProfundo);
  if (v && typeof v === 'object') {
    const copia = Object.create(Object.getPrototypeOf(v)) as Record<string, unknown>;
    for (const k of Object.keys(v)) copia[k] = clonarProfundo((v as Record<string, unknown>)[k]);
    return copia;
  }
  return v;
}
const clonar = <T>(x: T): T => clonarProfundo(x) as T;

class MapaBase<T extends { id: string }> {
  protected datos = new Map<string, T>();
  async guardar(x: T): Promise<void> {
    this.datos.set(x.id, clonar(x));
  }
  async buscarPorId(id: string): Promise<T | null> {
    const x = this.datos.get(id);
    return x ? clonar(x) : null;
  }
  protected todos(): T[] {
    return [...this.datos.values()].map(clonar);
  }
}

export class PerfilesMemoria extends PerfilPacienteRepository {
  private m = new MapaBase<PerfilPaciente>();
  guardar = (p: PerfilPaciente) => this.m.guardar(p);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async buscarPorIds(ids: string[]) {
    return (await Promise.all(ids.map((i) => this.m.buscarPorId(i)))).filter((x): x is PerfilPaciente => !!x);
  }
  async buscarPorTitular(usuarioId: string) {
    return this.m['todos']().filter((p) => p.titularUsuarioId === usuarioId);
  }
}

export class MedicosMemoria extends MedicoRepository {
  private m = new MapaBase<Medico>();
  guardar = (x: Medico) => this.m.guardar(x);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async buscarPorIds(ids: string[]) {
    return this.m['todos']().filter((x) => ids.includes(x.id));
  }
  async buscarPorUsuario(usuarioId: string) {
    return this.m['todos']().find((x) => x.usuarioId === usuarioId) ?? null;
  }
  async buscarDirectorio(f: FiltrosDirectorio) {
    return this.m['todos']().filter(
      (x) => x.estadoVerificacion === EstadoVerificacion.APROBADO && (!f.especialidad || x.especialidades.includes(f.especialidad)),
    );
  }
  async buscarConCredencialesPendientes() {
    return this.m['todos']().filter((x) => x.tieneCredencialesPendientes());
  }
  async listarEspecialidades() {
    return [...new Set(this.m['todos']().flatMap((x) => x.especialidades))];
  }
}

export class CitasMemoria extends CitaRepository {
  private m = new MapaBase<Cita>();
  async guardar(c: Cita) {
    const choque = this.m['todos']().find((x) => x.id !== c.id && x.ocupaFranja && c.ocupaFranja && x.medicoId === c.medicoId && x.inicio.getTime() === c.inicio.getTime());
    if (choque) throw Object.assign(new Error('E11000 duplicate key'), { code: 11000 });
    await this.m.guardar(c);
  }
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async existeSolapamiento(medicoId: string, inicio: Date, fin: Date, excluirId?: string) {
    return this.m['todos']().some((c) => c.id !== excluirId && c.medicoId === medicoId && c.ocupaFranja && c.inicio < fin && c.fin > inicio);
  }
  async buscarOcupadas(medicoId: string, desde: Date, hasta: Date) {
    return this.m['todos']().filter((c) => c.medicoId === medicoId && c.ocupaFranja && c.inicio < hasta && c.fin > desde);
  }
  async listarPorPacientes(ids: string[], f: FiltrosCitas) {
    return this.m['todos']().filter((c) => ids.includes(c.pacienteId) && (!f.estados || f.estados.includes(c.estado)));
  }
  async listarPorMedico(medicoId: string, f: FiltrosCitas) {
    return this.m['todos']().filter((c) => c.medicoId === medicoId && (!f.estados || f.estados.includes(c.estado)));
  }
  async buscarPropuestasVencidas(ahora: Date) {
    return this.m['todos']().filter((c) => c.estado === EstadoCita.PENDIENTE_ACEPTACION && c.propuestaExpiraEn! <= ahora);
  }
  async existeAtendida(pacienteId: string, medicoId: string) {
    return this.m['todos']().some((c) => c.pacienteId === pacienteId && c.medicoId === medicoId && c.estado === EstadoCita.ATENDIDA);
  }
}

export class PagosMemoria extends PagoRepository {
  private m = new MapaBase<Pago>();
  guardar = (p: Pago) => this.m.guardar(p);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async buscarPorCita(citaId: string) {
    return this.m['todos']().find((p) => p.citaId === citaId) ?? null;
  }
  async buscarPorCitas(ids: string[]) {
    return this.m['todos']().filter((p) => ids.includes(p.citaId));
  }
  async buscarPorClaveIdempotencia(clave: string) {
    return this.m['todos']().find((p) => p.claveIdempotencia === clave) ?? null;
  }
  async buscarListosParaLiberar(ahora: Date) {
    return this.m['todos']().filter((p) => p.puedeLiberarse(ahora));
  }
  async buscarEnDisputa() {
    return this.m['todos']().filter((p) => p.estado === EstadoPago.EN_DISPUTA);
  }
}

export class ExpedientesMemoria extends ExpedienteRepository {
  private m = new MapaBase<ExpedienteClinico>();
  guardar = (e: ExpedienteClinico) => this.m.guardar(e);
  async buscarPorPaciente(pacienteId: string) {
    return this.m['todos']().find((e) => e.pacienteId === pacienteId) ?? null;
  }
}

export class PermisosMemoria extends PermisoAccesoRepository {
  private m = new MapaBase<PermisoAcceso>();
  guardar = (p: PermisoAcceso) => this.m.guardar(p);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async buscarVigentes(pacienteId: string, medicoId: string, fecha: Date) {
    return this.m['todos']().filter((p) => p.pacienteId === pacienteId && p.medicoId === medicoId && p.estaVigente(fecha));
  }
  async listarPorPaciente(pacienteId: string) {
    return this.m['todos']().filter((p) => p.pacienteId === pacienteId);
  }
  async listarVigentesPorMedico(medicoId: string, fecha: Date) {
    return this.m['todos']().filter((p) => p.medicoId === medicoId && p.estaVigente(fecha));
  }
}

export class EventosMemoria extends EventoClinicoRepository {
  private m = new MapaBase<EventoClinico>();
  guardar = (e: EventoClinico) => this.m.guardar(e);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async listarPorPaciente(pacienteId: string, categorias: CategoriaClinica[], tipo: TipoEvento | undefined, p: Paginacion) {
    const todos = this.m['todos']()
      .filter((e) => e.pacienteId === pacienteId && categorias.includes(e.categoria) && (!tipo || e.tipo === tipo))
      .sort((a, b) => b.fecha.getTime() - a.fecha.getTime());
    return { items: todos.slice((p.pagina - 1) * p.tamano, p.pagina * p.tamano), total: todos.length };
  }
  async actualizarDetallesPorDocumento(documentoOrigenId: string, tipo: TipoEvento, detalles: Record<string, string>) {
    for (const e of this.m['todos']().filter((x) => x.documentoOrigenId === documentoOrigenId && x.tipo === tipo)) {
      e.detalles = { ...e.detalles, ...detalles };
      await this.m.guardar(e);
    }
  }
}

export class ReferenciasMemoria extends ReferenciaRepository {
  private m = new MapaBase<ReferenciaEspecialista>();
  guardar = (r: ReferenciaEspecialista) => this.m.guardar(r);
  buscarPorId = (id: string) => this.m.buscarPorId(id);
  async listarPorPacientes(ids: string[]) {
    return this.m['todos']().filter((r) => ids.includes(r.pacienteId));
  }
  async listarPorMedico(medicoId: string) {
    return this.m['todos']().filter((r) => r.medicoOrigenId === medicoId || r.medicoDestinoId === medicoId);
  }
}

export class FichasMemoria extends FichaEmergenciaRepository {
  private m = new MapaBase<FichaEmergencia>();
  guardar = (f: FichaEmergencia) => this.m.guardar(f);
  async buscarPorPaciente(pacienteId: string) {
    return this.m['todos']().find((f) => f.pacienteId === pacienteId) ?? null;
  }
  async buscarPorTokenHash(hash: string) {
    return this.m['todos']().find((f) => f.tokenQrHash === hash) ?? null;
  }
  lecturas = 0;
}

export class CacheMemoria extends FichaEmergenciaCache {
  datos = new Map<string, FichaCacheada>();
  async obtener(h: string) {
    return this.datos.get(h) ?? null;
  }
  async guardar(h: string, v: FichaCacheada) {
    this.datos.set(h, structuredClone(v));
  }
  async invalidar(h: string) {
    this.datos.delete(h);
  }
}

export class PasarelaFalsa extends PasarelaPagos {
  aprobar = true;
  operaciones: string[] = [];
  async autorizar(monto: number): Promise<ResultadoPasarela> {
    this.operaciones.push(`autorizar:${monto}`);
    return this.aprobar ? { aprobado: true, referencia: `REF-${generarId()}` } : { aprobado: false, mensaje: 'Fondos insuficientes' };
  }
  async capturar(_r: string, monto: number): Promise<ResultadoPasarela> {
    this.operaciones.push(`capturar:${monto}`);
    return { aprobado: true };
  }
  async reembolsar(_r: string, monto: number): Promise<ResultadoPasarela> {
    this.operaciones.push(`reembolsar:${monto}`);
    return { aprobado: true };
  }
}

export class NotificadorFalso extends Notificador {
  enviadas: NuevaNotificacion[] = [];
  async notificar(n: NuevaNotificacion) {
    this.enviadas.push(n);
  }
}

export class AuditoriaFalsa extends RegistroAuditoria {
  entradas: EntradaAuditoria[] = [];
  async registrar(e: EntradaAuditoria) {
    this.entradas.push(e);
  }
}

export class CifradorFalso extends CifradorCampos {
  cifrar = (t: string) => `enc:${t}`;
  descifrar = (t: string) => t.replace(/^enc:/, '');
  huella = (t: string) => createHmac('sha256', 'k').update(t).digest('hex');
}

export class AlmacenamientoFalso extends AlmacenamientoArchivos {
  archivos = new Map<string, ArchivoLeido>();
  async guardar(carpeta: string, contenido: Buffer, tipoMime: string, nombreOriginal: string): Promise<ArchivoGuardado> {
    const ruta = `${carpeta}/${generarId()}`;
    this.archivos.set(ruta, { contenido, tipoMime, nombreOriginal });
    return { ruta, tipoMime, tamanoBytes: contenido.length, nombreOriginal };
  }
  async leer(ruta: string) {
    return this.archivos.get(ruta)!;
  }
  generarUrlLectura(ruta: string) {
    return `http://test/archivos/${Buffer.from(ruta).toString('base64url')}`;
  }
  resolverTokenLectura(token: string) {
    return Buffer.from(token, 'base64url').toString();
  }
}

export class KmsMemoria extends Kms {
  private llaves = new Map<string, { privada: KeyObject; publica: string }>();
  async crearLlaveFirma() {
    const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
    const id = `llave-${createHash('sha1').update(generarId()).digest('hex').slice(0, 8)}`;
    this.llaves.set(id, { privada: privateKey, publica: publicKey.export({ type: 'spki', format: 'pem' }).toString() });
    return id;
  }
  async firmar(id: string, contenido: Buffer) {
    return sign('sha256', contenido, this.llaves.get(id)!.privada).toString('base64');
  }
  async obtenerLlavePublica(id: string) {
    return this.llaves.get(id)!.publica;
  }
}
