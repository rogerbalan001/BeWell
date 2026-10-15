import { Injectable } from '@nestjs/common';
import { Notificador } from '../../../shared/application/notificador';
import { AccesoDenegadoError, NoEncontradoError } from '../../../shared/domain/errores';
import { Reloj, sumarDias } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { CategoriaClinica, TipoEvento } from '../domain/categoria-clinica';
import { ReferenciaEspecialista } from '../domain/referencia-especialista';
import { ReferenciaRepository } from '../domain/repositorios';
import { ExpedienteService } from './expediente.service';
import { PoliticaAccesoExpediente } from './politica-acceso-expediente';

export const DIAS_ACCESO_POR_REFERENCIA = 90;

/** «Control» HU: referir pacientes a especialistas de la red compartiendo su expediente. */
@Injectable()
export class ReferenciasService {
  constructor(
    private readonly referencias: ReferenciaRepository,
    private readonly politica: PoliticaAccesoExpediente,
    private readonly expediente: ExpedienteService,
    private readonly medicos: MedicosService,
    private readonly perfiles: PerfilesService,
    private readonly notificador: Notificador,
    private readonly reloj: Reloj,
  ) {}

  async referir(actor: Actor, datos: { pacienteId: string; medicoDestinoId: string; motivo: string }): Promise<ReferenciaEspecialista> {
    if (!actor.medicoId) throw new AccesoDenegadoError('Solo un médico puede emitir referencias');
    await this.politica.asegurarLectura(actor, datos.pacienteId);
    const [origen, destino, paciente] = await Promise.all([
      this.medicos.obtener(actor.medicoId),
      this.medicos.obtenerPublico(datos.medicoDestinoId),
      this.perfiles.obtener(datos.pacienteId),
    ]);
    const referencia = ReferenciaEspecialista.emitir(
      {
        pacienteId: datos.pacienteId,
        medicoOrigenId: origen.id,
        medicoDestinoId: destino.id,
        especialidadDestino: destino.especialidades[0],
        motivo: datos.motivo,
      },
      this.reloj.ahora(),
    );
    await this.referencias.guardar(referencia);
    await this.notificador.notificar({
      usuarioId: paciente.titularUsuarioId,
      tipo: 'REFERENCIA',
      titulo: 'Te refirieron a un especialista',
      mensaje: `${origen.nombreCompleto} propone referir a ${paciente.nombres} con ${destino.nombreCompleto} (${referencia.especialidadDestino}). Aprueba para compartir el expediente.`,
      datos: { referenciaId: referencia.id, pacienteId: paciente.id },
    });
    return referencia;
  }

  /** El paciente aprueba: el especialista recibe acceso al expediente y una notificación. */
  async aprobar(actor: Actor, referenciaId: string): Promise<ReferenciaEspecialista> {
    const referencia = await this.obtener(referenciaId);
    await this.perfiles.asegurarGestion(actor, referencia.pacienteId);
    const ahora = this.reloj.ahora();
    referencia.aprobar(ahora);
    await this.referencias.guardar(referencia);

    const accesoOrigen = await this.politica.evaluar(
      { id: '', email: '', roles: [], medicoId: referencia.medicoOrigenId },
      referencia.pacienteId,
    );
    const categorias = accesoOrigen.categorias.length
      ? accesoOrigen.categorias.filter((c) => c !== CategoriaClinica.SALUD_MENTAL)
      : [CategoriaClinica.CONSULTAS, CategoriaClinica.DIAGNOSTICOS, CategoriaClinica.LABORATORIOS];
    await this.expediente.concederPorReferencia(
      referencia.pacienteId,
      referencia.medicoDestinoId,
      categorias.length ? categorias : [CategoriaClinica.CONSULTAS],
      sumarDias(ahora, DIAS_ACCESO_POR_REFERENCIA),
      actor.id,
    );

    const [origen, destino] = await Promise.all([
      this.medicos.obtener(referencia.medicoOrigenId),
      this.medicos.obtener(referencia.medicoDestinoId),
    ]);
    await this.expediente.registrarEvento({
      pacienteId: referencia.pacienteId,
      tipo: TipoEvento.REFERENCIA,
      fecha: ahora,
      titulo: `Referencia a ${referencia.especialidadDestino}`,
      resumen: referencia.motivo,
      medicoId: origen.id,
      documentoOrigenId: referencia.id,
      detalles: { medicoDestino: destino.nombreCompleto, especialidadDestino: referencia.especialidadDestino },
    });
    const paciente = await this.perfiles.obtener(referencia.pacienteId);
    await this.notificador.notificar({
      usuarioId: destino.usuarioId,
      tipo: 'REFERENCIA',
      titulo: 'Nueva referencia recibida',
      mensaje: `${origen.nombreCompleto} te refirió a ${paciente.nombreCompleto}. Ya puedes ver su expediente y proponerle horarios de cita.`,
      datos: { referenciaId: referencia.id, pacienteId: paciente.id },
    });
    return referencia;
  }

  async rechazar(actor: Actor, referenciaId: string): Promise<ReferenciaEspecialista> {
    const referencia = await this.obtener(referenciaId);
    await this.perfiles.asegurarGestion(actor, referencia.pacienteId);
    referencia.rechazar(this.reloj.ahora());
    await this.referencias.guardar(referencia);
    return referencia;
  }

  async listar(actor: Actor): Promise<ReferenciaEspecialista[]> {
    if (actor.medicoId) return this.referencias.listarPorMedico(actor.medicoId);
    const perfiles = await this.perfiles.listarPerfiles(actor.id);
    return this.referencias.listarPorPacientes(perfiles.map((p) => p.id));
  }

  async obtener(id: string): Promise<ReferenciaEspecialista> {
    const referencia = await this.referencias.buscarPorId(id);
    if (!referencia) throw new NoEncontradoError('Referencia', id);
    return referencia;
  }
}
