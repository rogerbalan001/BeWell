import { Injectable } from '@nestjs/common';
import { AccesoDenegadoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { CategoriaClinica, TODAS_LAS_CATEGORIAS } from '../domain/categoria-clinica';
import { PermisoAccesoRepository } from '../domain/repositorios';

export interface AccesoExpediente {
  esTitular: boolean;
  categorias: CategoriaClinica[];
  categoriasEscritura: CategoriaClinica[];
}

/**
 * «Control» PoliticaAccesoExpediente. Regla única que decide qué puede ver o
 * escribir un actor en un expediente: el titular ve todo; un médico solo las
 * secciones de sus permisos vigentes (no revocados y no vencidos).
 */
@Injectable()
export class PoliticaAccesoExpediente {
  constructor(
    private readonly perfiles: PerfilesService,
    private readonly permisos: PermisoAccesoRepository,
    private readonly reloj: Reloj,
  ) {}

  async evaluar(actor: Actor, pacienteId: string): Promise<AccesoExpediente> {
    await this.perfiles.obtener(pacienteId); // 404 si no existe
    if (await this.perfiles.puedeGestionar(actor.id, pacienteId)) {
      return { esTitular: true, categorias: [...TODAS_LAS_CATEGORIAS], categoriasEscritura: [...TODAS_LAS_CATEGORIAS] };
    }
    if (!actor.medicoId) return { esTitular: false, categorias: [], categoriasEscritura: [] };
    const ahora = this.reloj.ahora();
    const vigentes = (await this.permisos.buscarVigentes(pacienteId, actor.medicoId, ahora)).filter((p) => p.estaVigente(ahora));
    const categorias = new Set<CategoriaClinica>();
    const escritura = new Set<CategoriaClinica>();
    for (const p of vigentes) {
      p.categoriasPermitidas.forEach((c) => categorias.add(c));
      if (p.escritura) p.categoriasPermitidas.forEach((c) => escritura.add(c));
    }
    return { esTitular: false, categorias: [...categorias], categoriasEscritura: [...escritura] };
  }

  /** Lanza 403 si el actor no puede leer ninguna sección del expediente. */
  async asegurarLectura(actor: Actor, pacienteId: string): Promise<AccesoExpediente> {
    const acceso = await this.evaluar(actor, pacienteId);
    if (!acceso.categorias.length) throw new AccesoDenegadoError('No tienes un permiso vigente sobre este expediente');
    return acceso;
  }

  async puedeLeer(actor: Actor, pacienteId: string, categoria: CategoriaClinica): Promise<boolean> {
    return (await this.evaluar(actor, pacienteId)).categorias.includes(categoria);
  }

  async asegurarLecturaDe(actor: Actor, pacienteId: string, categoria: CategoriaClinica): Promise<AccesoExpediente> {
    const acceso = await this.evaluar(actor, pacienteId);
    if (!acceso.categorias.includes(categoria)) {
      throw new AccesoDenegadoError(`El paciente no te ha dado acceso a la sección ${categoria}`);
    }
    return acceso;
  }

  async asegurarEscritura(actor: Actor, pacienteId: string, categoria: CategoriaClinica): Promise<AccesoExpediente> {
    const acceso = await this.evaluar(actor, pacienteId);
    if (!acceso.categoriasEscritura.includes(categoria)) {
      throw new AccesoDenegadoError(`No tienes permiso de escritura en la sección ${categoria}`);
    }
    return acceso;
  }
}
