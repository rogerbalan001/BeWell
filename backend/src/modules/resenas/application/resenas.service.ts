import { Injectable } from '@nestjs/common';
import { AccesoDenegadoError, ConflictoError, NoEncontradoError, ReglaNegocioError } from '../../../shared/domain/errores';
import { Reloj } from '../../../shared/domain/reloj';
import { Actor } from '../../../shared/domain/roles';
import { CitasService } from '../../citas/application/citas.service';
import { EstadoCita } from '../../citas/domain/cita';
import { MedicosService } from '../../medicos/application/medicos.service';
import { PerfilesService } from '../../perfiles/application/perfiles.service';
import { Calificaciones, EstadisticasMedico, ResenaRepository, ResenaVerificada } from '../domain/resena-verificada';

/** «Control» HU: leer y dejar reseñas solo de consultas realmente atendidas. */
@Injectable()
export class ResenasService {
  constructor(
    private readonly resenas: ResenaRepository,
    private readonly citas: CitasService,
    private readonly perfiles: PerfilesService,
    private readonly medicos: MedicosService,
    private readonly reloj: Reloj,
  ) {}

  async publicar(actor: Actor, citaId: string, datos: Calificaciones & { comentario?: string }): Promise<ResenaVerificada> {
    const cita = await this.citas.obtenerPorId(citaId);
    if (!(await this.perfiles.puedeGestionar(actor.id, cita.pacienteId))) {
      throw new AccesoDenegadoError('Solo el paciente de la cita puede reseñarla');
    }
    if (cita.estado !== EstadoCita.ATENDIDA) throw new ReglaNegocioError('Solo puedes reseñar consultas atendidas');
    if (await this.resenas.buscarPorCita(citaId)) throw new ConflictoError('Esta cita ya tiene una reseña');
    const resena = ResenaVerificada.publicar(
      { ...datos, citaId, pacienteId: cita.pacienteId, medicoId: cita.medicoId, autorUsuarioId: actor.id },
      this.reloj.ahora(),
    );
    await this.resenas.guardar(resena);
    await this.recalcular(cita.medicoId);
    return resena;
  }

  async editar(actor: Actor, resenaId: string, datos: Calificaciones & { comentario?: string }): Promise<ResenaVerificada> {
    const resena = await this.resenas.buscarPorId(resenaId);
    if (!resena) throw new NoEncontradoError('Reseña', resenaId);
    if (resena.autorUsuarioId !== actor.id) throw new AccesoDenegadoError('Solo el autor puede editar la reseña');
    resena.editar(datos, this.reloj.ahora());
    await this.resenas.guardar(resena);
    await this.recalcular(resena.medicoId);
    return resena;
  }

  async obtenerPorCita(actor: Actor, citaId: string): Promise<ResenaVerificada | null> {
    await this.citas.obtenerParaActor(actor, citaId);
    return this.resenas.buscarPorCita(citaId);
  }

  async listarPorMedico(medicoId: string): Promise<{ resenas: ResenaVerificada[]; estadisticas: EstadisticasMedico }> {
    const [resenas, estadisticas] = await Promise.all([
      this.resenas.listarPorMedico(medicoId, 50),
      this.resenas.estadisticas(medicoId),
    ]);
    return { resenas, estadisticas };
  }

  private async recalcular(medicoId: string): Promise<void> {
    const e = await this.resenas.estadisticas(medicoId);
    await this.medicos.actualizarCalificacion(medicoId, e.promedio, e.total);
  }
}
