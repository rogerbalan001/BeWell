/**
 * Raíz de composición para pruebas: conecta los servicios «Control» con
 * adaptadores en memoria, igual que lo hace el contenedor de NestJS en producción.
 */
import { aCentavos } from '../../src/shared/domain/dinero';
import { GeneradorPdfTexto } from '../../src/shared/infrastructure/pdf/generador-pdf-texto';
import { Actor, RolUsuario } from '../../src/shared/domain/roles';
import { CitasService } from '../../src/modules/citas/application/citas.service';
import { EmergenciaService } from '../../src/modules/emergencias/application/emergencia.service';
import { ExpedienteService } from '../../src/modules/expediente/application/expediente.service';
import { PoliticaAccesoExpediente } from '../../src/modules/expediente/application/politica-acceso-expediente';
import { ReferenciasService } from '../../src/modules/expediente/application/referencias.service';
import { AgendaService } from '../../src/modules/medicos/application/agenda.service';
import { MedicosService } from '../../src/modules/medicos/application/medicos.service';
import { VerificacionProfesionalService } from '../../src/modules/medicos/application/verificacion-profesional.service';
import { TipoPolitica } from '../../src/modules/medicos/domain/politica-cancelacion';
import { PagosService } from '../../src/modules/pagos/application/pagos.service';
import { PerfilesService } from '../../src/modules/perfiles/application/perfiles.service';
import { FirmaDigitalService } from '../../src/modules/recipes/application/firma-digital.service';
import { RecipesService } from '../../src/modules/recipes/application/recipes.service';
import { RecipeDigital, RecipeRepository } from '../../src/modules/recipes/domain/recipe-digital';
import {
  AlmacenamientoFalso,
  AuditoriaFalsa,
  CacheMemoria,
  CitasMemoria,
  EventosMemoria,
  ExpedientesMemoria,
  FichasMemoria,
  KmsMemoria,
  MedicosMemoria,
  NotificadorFalso,
  PagosMemoria,
  PasarelaFalsa,
  PerfilesMemoria,
  PermisosMemoria,
  ReferenciasMemoria,
  RelojFijo,
} from './memoria';

class RecipesMemoria extends RecipeRepository {
  datos = new Map<string, RecipeDigital>();
  async guardar(r: RecipeDigital) {
    this.datos.set(r.id, new RecipeDigital(structuredClone({ ...r })));
  }
  async buscarPorId(id: string) {
    return this.datos.get(id) ?? null;
  }
  async buscarPorCodigo(c: string) {
    return [...this.datos.values()].find((r) => r.codigoVerificacion === c) ?? null;
  }
  async listarPorPaciente(id: string) {
    return [...this.datos.values()].filter((r) => r.pacienteId === id);
  }
  async listarPorMedico(id: string) {
    return [...this.datos.values()].filter((r) => r.medicoId === id);
  }
}

const config = { get: (k: string) => (k === 'PUBLIC_WEB_URL' ? 'https://app.test/#' : undefined), getOrThrow: () => 'x' };

/** Lunes 2026-10-12 12:00 UTC (08:00 en Caracas). */
export const LUNES_8AM_CARACAS = new Date('2026-10-12T12:00:00.000Z');

export function crearContexto(ahora = LUNES_8AM_CARACAS) {
  const reloj = new RelojFijo(ahora);
  const notificador = new NotificadorFalso();
  const auditoria = new AuditoriaFalsa();
  const almacenamiento = new AlmacenamientoFalso();
  const pasarela = new PasarelaFalsa();
  const repos = {
    perfiles: new PerfilesMemoria(),
    medicos: new MedicosMemoria(),
    citas: new CitasMemoria(),
    pagos: new PagosMemoria(),
    expedientes: new ExpedientesMemoria(),
    permisos: new PermisosMemoria(),
    eventos: new EventosMemoria(),
    referencias: new ReferenciasMemoria(),
    fichas: new FichasMemoria(),
    recipes: new RecipesMemoria(),
  };
  const cache = new CacheMemoria();
  const kms = new KmsMemoria();

  const perfiles = new PerfilesService(repos.perfiles, reloj);
  const medicos = new MedicosService(repos.medicos, reloj);
  const verificacion = new VerificacionProfesionalService(repos.medicos, medicos, almacenamiento, notificador, reloj);
  const agenda = new AgendaService(repos.medicos, medicos);
  const pagos = new PagosService(repos.pagos, pasarela, reloj);
  const politica = new PoliticaAccesoExpediente(perfiles, repos.permisos, reloj);
  const expediente = new ExpedienteService(
    repos.expedientes,
    repos.eventos,
    repos.permisos,
    politica,
    perfiles,
    medicos,
    auditoria,
    notificador,
    reloj,
    new GeneradorPdfTexto(),
    almacenamiento,
  );
  const referencias = new ReferenciasService(repos.referencias, politica, expediente, medicos, perfiles, notificador, reloj);
  const citas = new CitasService(repos.citas, medicos, perfiles, pagos, expediente, referencias, notificador, reloj);
  const firma = new FirmaDigitalService(kms);
  const recipes = new RecipesService(repos.recipes, firma, kms, citas, medicos, perfiles, expediente, politica, notificador, auditoria, reloj);
  const emergencia = new EmergenciaService(repos.fichas, cache, perfiles, auditoria, notificador, reloj, config as never);

  const admin: Actor = { id: 'a'.repeat(24), email: 'admin@test', roles: [RolUsuario.ADMIN] };

  /** Crea un médico verificado con horario L–V 08:00–12:00 (bloques de 30 min). */
  async function medicoVerificado(nombre: string, politicaTipo: TipoPolitica = 'MODERADA', tarifa = 50) {
    const usuarioId = Math.random().toString(16).slice(2).padEnd(24, '0').slice(0, 24);
    const m = await medicos.registrarMedico(usuarioId, {
      nombres: nombre,
      apellidos: 'Prueba',
      especialidades: ['Medicina General'],
      tarifaConsulta: aCentavos(tarifa),
    });
    const actor: Actor = { id: usuarioId, email: `${nombre}@test`, roles: [RolUsuario.MEDICO], medicoId: m.id };
    for (const tipo of ['TITULO', 'COLEGIATURA', 'CEDULA'] as const) {
      const c = await verificacion.registrarCredencial(actor, tipo, '123', { contenido: Buffer.from('x'), tipoMime: 'application/pdf', nombreOriginal: 'x.pdf' });
      await verificacion.aprobarCredencial(admin.id, m.id, c.id);
    }
    await agenda.configurarHorario(
      actor,
      [1, 2, 3, 4, 5].map((d) => ({ diaSemana: d, horaInicio: '08:00', horaFin: '12:00', duracionCitaMin: 30 })),
    );
    await agenda.configurarPolitica(actor, politicaTipo);
    return actor;
  }

  async function pacienteTitular(nombre = 'Sofía') {
    const usuarioId = Math.random().toString(16).slice(2).padEnd(24, '1').slice(0, 24);
    const perfil = await perfiles.crearPerfilTitular(usuarioId, {
      nombres: nombre,
      apellidos: 'Morales',
      fechaNacimiento: new Date('1992-05-14'),
      sexo: 'F',
    });
    const actor: Actor = { id: usuarioId, email: `${nombre}@test`, roles: [RolUsuario.PACIENTE] };
    return { actor, perfil };
  }

  return {
    reloj, notificador, auditoria, pasarela, repos, cache, kms, almacenamiento,
    perfiles, medicos, verificacion, agenda, pagos, politica, expediente, referencias, citas, firma, recipes, emergencia,
    admin, medicoVerificado, pacienteTitular,
  };
}
