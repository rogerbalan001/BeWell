import { Injectable } from '@nestjs/common';
import { Notificador } from '../../../shared/application/notificador';
import { RegistroAuditoria } from '../../../shared/application/registro-auditoria';
import { AccesoDenegadoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { CitasService } from '../../citas/application/citas.service';
import { EstadoCita } from '../../citas/domain/cita';
import { ExpedienteService } from '../../expediente/application/expediente.service';
import { PoliticaAccesoExpediente } from '../../expediente/application/politica-acceso-expediente';
import { CategoriaClinica, TipoEvento } from '../../expediente/domain/categoria-clinica';
import { MedicosService } from '../../medicos/application/medicos.service';
import { Medico } from '../../medicos/domain/medico';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { PerfilPaciente } from '../../perfiles/domain/perfil-paciente';
import { ItemRecipe, RecipeDigital, RecipeRepository } from '../domain/recipe-digital';
import { FirmaDigitalService } from './firma-digital.service';
import { Kms } from './kms';

export interface ResultadoVerificacion {
  encontrado: boolean;
  valido: boolean;
  firmaValida: boolean;
  integro: boolean;
  vigente: boolean;
  recipe?: RecipeDigital;
  medico?: Medico;
  paciente?: PerfilPaciente;
}

/** «Control» HU: emitir récipes digitales con firma y código verificable. */
@Injectable()
export class RecipesService {
  constructor(
    private readonly recipes: RecipeRepository,
    private readonly firma: FirmaDigitalService,
    private readonly kms: Kms,
    private readonly citas: CitasService,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
    private readonly expediente: ExpedienteService,
    private readonly politica: PoliticaAccesoExpediente,
    private readonly notificador: Notificador,
    private readonly auditoria: RegistroAuditoria,
    private readonly reloj: Reloj,
  ) {}

  async emitir(actor: Actor, citaId: string, datos: { items: ItemRecipe[]; diagnostico?: string; validoDias?: number }): Promise<RecipeDigital> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede emitir récipes');
    const cita = await this.citas.obtenerPorId(citaId);
    if (cita.medicoId !== actor.medicoId) throw new AccesoDenegadoError('La cita no pertenece a este médico');
    if (cita.estado !== EstadoCita.ATENDIDA) throw new ReglaNegocioError('Solo se emiten récipes de consultas atendidas');

    let medico = await this.medicos.obtener(actor.medicoId);
    if (!medico.estaVerificado()) throw new AccesoDenegadoError('Tu perfil debe estar verificado para firmar récipes');
    if (!medico.llaveFirmaId) {
      await this.medicos.asignarLlaveFirma(medico.id, await this.kms.crearLlaveFirma());
      medico = await this.medicos.obtener(medico.id);
    }

    const recipe = RecipeDigital.borrador(
      { citaId, medicoId: medico.id, pacienteId: cita.pacienteId, items: datos.items, diagnostico: datos.diagnostico, validoDias: datos.validoDias ?? 30 },
      this.reloj.ahora(),
    );
    const { hash, firma } = await this.firma.firmar(medico.llaveFirmaId!, recipe.contenidoFirmable());
    recipe.firmar(hash, firma, medico.llaveFirmaId!);
    await this.recipes.guardar(recipe);

    // HU: el récipe se guarda automáticamente en el expediente del paciente.
    await this.expediente.registrarEvento({
      pacienteId: recipe.pacienteId,
      tipo: TipoEvento.RECETA,
      fecha: recipe.emitidoEn,
      titulo: `Récipe ${recipe.codigoVerificacion}`,
      resumen: recipe.items.map((i) => `${i.medicamento} ${i.presentacion} — ${i.dosis}, ${i.frecuencia} por ${i.duracionDias} días`).join('\n'),
      medicoId: medico.id,
      autorUsuarioId: actor.id,
      documentoOrigenId: recipe.id,
      detalles: { codigoVerificacion: recipe.codigoVerificacion },
    });
    await this.notificador.notificar({
      usuarioId: await this.perfiles.titularDe(recipe.pacienteId),
      tipo: 'RECIPE',
      titulo: 'Nuevo récipe digital',
      mensaje: `${medico.nombreCompleto} emitió el récipe ${recipe.codigoVerificacion}. Muéstralo en la farmacia con su código QR.`,
      datos: { recipeId: recipe.id },
    });
    return recipe;
  }

  async anular(actor: Actor, recipeId: string, motivo: string): Promise<RecipeDigital> {
    const recipe = await this.obtenerRecipe(recipeId);
    if (recipe.medicoId !== actor.medicoId) throw new AccesoDenegadoError('Solo el médico emisor puede anular el récipe');
    recipe.anular(motivo, this.reloj.ahora());
    await this.recipes.guardar(recipe);
    return recipe;
  }

  async listarPorPaciente(actor: Actor, pacienteId: string): Promise<RecipeDigital[]> {
    await this.politica.asegurarLecturaDe(actor, pacienteId, CategoriaClinica.RECETAS);
    return this.recipes.listarPorPaciente(pacienteId);
  }

  async listarEmitidos(actor: Actor): Promise<RecipeDigital[]> {
    if (!actor.medicoId) throw new AccesoDenegadoError();
    return this.recipes.listarPorMedico(actor.medicoId);
  }

  async obtener(actor: Actor, recipeId: string): Promise<RecipeDigital> {
    const recipe = await this.obtenerRecipe(recipeId);
    if (recipe.medicoId !== actor.medicoId) {
      await this.politica.asegurarLecturaDe(actor, recipe.pacienteId, CategoriaClinica.RECETAS);
    }
    return recipe;
  }

  /** Verificación pública (farmacias): emisor, fecha, estado e integridad del contenido. */
  async verificar(codigo: string, ip?: string): Promise<ResultadoVerificacion> {
    const recipe = await this.recipes.buscarPorCodigo(codigo.trim().toUpperCase());
    if (!recipe) return { encontrado: false, valido: false, firmaValida: false, integro: false, vigente: false };
    const { firmaValida, hash } = await this.firma.verificar(recipe.contenidoFirmable(), recipe.firma, recipe.llaveFirmaId);
    const integro = hash === recipe.hashContenido;
    const vigente = recipe.estaVigente(this.reloj.ahora());
    const [medico, paciente] = await Promise.all([this.medicos.obtener(recipe.medicoId), this.perfiles.obtener(recipe.pacienteId)]);
    await this.auditoria.registrar({
      rolActor: 'VERIFICADOR_PUBLICO',
      accion: 'VERIFICAR_RECIPE',
      recurso: 'recipe',
      recursoId: recipe.id,
      pacienteId: recipe.pacienteId,
      ip,
    });
    return { encontrado: true, valido: firmaValida && integro && vigente, firmaValida, integro, vigente, recipe, medico, paciente };
  }

  private async obtenerRecipe(id: string): Promise<RecipeDigital> {
    const recipe = await this.recipes.buscarPorId(id);
    if (!recipe) throw new NoEncontradoError('Récipe', id);
    return recipe;
  }
}
