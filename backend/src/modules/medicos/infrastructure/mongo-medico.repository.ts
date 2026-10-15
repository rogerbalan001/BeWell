import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';
import { aDecimal128, deDecimal128, oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { CredencialProfesional, EstadoVerificacion, TipoCredencial } from '../domain/credencial-profesional';
import { Medico, Modalidad } from '../domain/medico';
import { FiltrosDirectorio, MedicoRepository } from '../domain/medico.repository';
import { PoliticaCancelacion, TipoPolitica } from '../domain/politica-cancelacion';
import { MedicoDoc } from './medico.schema';

const escaparRegex = (texto: string): string => texto.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

@Injectable()
export class MongoMedicoRepository extends MedicoRepository {
  constructor(@InjectModel(MedicoDoc.name) private readonly modelo: Model<MedicoDoc>) {
    super();
  }

  async guardar(m: Medico): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(m.id) },
      {
        _id: oid(m.id),
        usuarioId: oid(m.usuarioId),
        nombres: m.nombres,
        apellidos: m.apellidos,
        especialidades: m.especialidades,
        tarifaConsulta: aDecimal128(m.tarifaConsulta),
        moneda: m.moneda,
        estadoVerificacion: m.estadoVerificacion,
        credenciales: m.credenciales.map((c) => ({ ...c, revisadoPorId: oidOpcional(c.revisadoPorId) })),
        politicaCancelacion: {
          tipo: m.politicaCancelacion.tipo,
          horasMinimasAviso: m.politicaCancelacion.horasMinimasAviso,
          porcentajePenalizacion: m.politicaCancelacion.porcentajePenalizacion,
        },
        horario: m.horario,
        modalidades: m.modalidades,
        direccionConsultorio: m.direccionConsultorio,
        biografia: m.biografia,
        zonaHorariaMin: m.zonaHorariaMin,
        calificacionPromedio: m.calificacionPromedio,
        totalResenas: m.totalResenas,
        llaveFirmaId: m.llaveFirmaId,
        creadoEn: m.creadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<Medico | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorIds(ids: string[]): Promise<Medico[]> {
    return (await this.modelo.find({ _id: { $in: ids.map(oid) } }).lean()).map((d) => this.aDominio(d));
  }

  async buscarPorUsuario(usuarioId: string): Promise<Medico | null> {
    const d = await this.modelo.findOne({ usuarioId: oid(usuarioId) }).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarDirectorio(f: FiltrosDirectorio): Promise<Medico[]> {
    const filtro: FilterQuery<MedicoDoc> = { estadoVerificacion: EstadoVerificacion.APROBADO };
    if (f.especialidad) filtro.especialidades = f.especialidad;
    if (f.modalidad) filtro.modalidades = f.modalidad;
    if (f.texto?.trim()) {
      const re = new RegExp(escaparRegex(f.texto.trim()), 'i');
      filtro.$or = [{ nombres: re }, { apellidos: re }, { especialidades: re }];
    }
    const docs = await this.modelo.find(filtro).sort({ calificacionPromedio: -1, totalResenas: -1 }).limit(100).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async buscarConCredencialesPendientes(): Promise<Medico[]> {
    const docs = await this.modelo.find({ 'credenciales.estado': EstadoVerificacion.PENDIENTE }).sort({ creadoEn: 1 }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async listarEspecialidades(): Promise<string[]> {
    const valores = (await this.modelo.distinct('especialidades', {
      estadoVerificacion: EstadoVerificacion.APROBADO,
    })) as string[];
    return valores.sort((a, b) => a.localeCompare(b, 'es'));
  }

  private aDominio(d: MedicoDoc): Medico {
    return new Medico({
      id: str(d._id),
      usuarioId: str(d.usuarioId),
      nombres: d.nombres,
      apellidos: d.apellidos,
      especialidades: d.especialidades,
      tarifaConsulta: deDecimal128(d.tarifaConsulta),
      moneda: d.moneda,
      estadoVerificacion: d.estadoVerificacion as EstadoVerificacion,
      credenciales: (d.credenciales ?? []).map(
        (c): CredencialProfesional => ({
          id: c.id,
          tipo: c.tipo as TipoCredencial,
          numero: c.numero,
          archivoRef: c.archivoRef,
          estado: c.estado as EstadoVerificacion,
          enviadaEn: c.enviadaEn,
          revisadoPorId: strOpcional(c.revisadoPorId),
          fechaRevision: c.fechaRevision,
          observaciones: c.observaciones,
        }),
      ),
      politicaCancelacion: new PoliticaCancelacion(
        d.politicaCancelacion.tipo as TipoPolitica,
        d.politicaCancelacion.horasMinimasAviso,
        d.politicaCancelacion.porcentajePenalizacion,
      ),
      horario: (d.horario ?? []).map((b) => ({ ...b })),
      modalidades: (d.modalidades ?? []) as Modalidad[],
      direccionConsultorio: d.direccionConsultorio,
      biografia: d.biografia,
      zonaHorariaMin: d.zonaHorariaMin,
      calificacionPromedio: d.calificacionPromedio ?? 0,
      totalResenas: d.totalResenas ?? 0,
      llaveFirmaId: d.llaveFirmaId,
      creadoEn: d.creadoEn,
    });
  }
}
