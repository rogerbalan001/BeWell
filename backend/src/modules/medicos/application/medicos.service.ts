import { Injectable } from '@nestjs/common';
import { Centavos } from '../../../shared/domain/dinero';
import { AccesoDenegadoError, NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { Medico, Modalidad } from '../domain/medico';
import { FiltrosDirectorio, MedicoRepository } from '../domain/medico.repository';

export interface DatosPerfilMedico {
  especialidades?: string[];
  tarifaConsulta?: Centavos;
  direccionConsultorio?: string;
  biografia?: string;
  modalidades?: Modalidad[];
}

/** «Control» del perfil público del médico y del directorio de especialistas. */
@Injectable()
export class MedicosService {
  constructor(
    private readonly medicos: MedicoRepository,
    private readonly reloj: Reloj,
  ) {}

  async registrarMedico(
    usuarioId: string,
    datos: { nombres: string; apellidos: string; especialidades: string[]; tarifaConsulta: Centavos },
  ): Promise<Medico> {
    const medico = Medico.registrar(usuarioId, datos, this.reloj.ahora());
    await this.medicos.guardar(medico);
    return medico;
  }

  directorio(filtros: FiltrosDirectorio): Promise<Medico[]> {
    return this.medicos.buscarDirectorio(filtros);
  }

  listarEspecialidades(): Promise<string[]> {
    return this.medicos.listarEspecialidades();
  }

  async obtener(id: string): Promise<Medico> {
    const medico = await this.medicos.buscarPorId(id);
    if (!medico) throw new NoEncontradoError('Médico', id);
    return medico;
  }

  /** Perfil visible para pacientes: solo si el médico está verificado. */
  async obtenerPublico(id: string): Promise<Medico> {
    const medico = await this.obtener(id);
    if (!medico.estaVerificado()) throw new NoEncontradoError('Médico', id);
    return medico;
  }

  obtenerVarios(ids: string[]): Promise<Medico[]> {
    return ids.length ? this.medicos.buscarPorIds([...new Set(ids)]) : Promise.resolve([]);
  }

  buscarPorUsuario(usuarioId: string): Promise<Medico | null> {
    return this.medicos.buscarPorUsuario(usuarioId);
  }

  /** Médico asociado al actor autenticado (rol MEDICO). */
  async delActor(actor: Actor): Promise<Medico> {
    if (!actor.medicoId) throw new AccesoDenegadoError('El usuario no tiene perfil de médico');
    return this.obtener(actor.medicoId);
  }

  async actualizarPerfil(actor: Actor, datos: DatosPerfilMedico): Promise<Medico> {
    const medico = await this.delActor(actor);
    if (datos.especialidades?.length) medico.especialidades = datos.especialidades;
    if (datos.tarifaConsulta && datos.tarifaConsulta > 0) medico.tarifaConsulta = datos.tarifaConsulta;
    if (datos.direccionConsultorio !== undefined) medico.direccionConsultorio = datos.direccionConsultorio;
    if (datos.biografia !== undefined) medico.biografia = datos.biografia;
    if (datos.modalidades?.length) medico.modalidades = datos.modalidades;
    await this.medicos.guardar(medico);
    return medico;
  }

  async asignarLlaveFirma(medicoId: string, llaveFirmaId: string): Promise<void> {
    const medico = await this.obtener(medicoId);
    medico.llaveFirmaId = llaveFirmaId;
    await this.medicos.guardar(medico);
  }

  /** Lo invoca el módulo de Reseñas al publicar o editar una reseña. */
  async actualizarCalificacion(medicoId: string, promedio: number, total: number): Promise<void> {
    const medico = await this.obtener(medicoId);
    medico.actualizarCalificacion(promedio, total);
    await this.medicos.guardar(medico);
  }
}
