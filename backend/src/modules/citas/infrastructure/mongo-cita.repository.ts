import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';
import { aDecimal128, deDecimal128, oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { Modalidad } from '../../medicos/domain/medico';
import { PoliticaCancelacion, TipoPolitica } from '../../medicos/domain/politica-cancelacion';
import { Cancelador, Cita, EstadoCita, Parte } from '../domain/cita';
import { CitaRepository, FiltrosCitas } from '../domain/cita.repository';
import { CitaDoc } from './cita.schema';

@Injectable()
export class MongoCitaRepository extends CitaRepository {
  constructor(@InjectModel(CitaDoc.name) private readonly modelo: Model<CitaDoc>) {
    super();
  }

  async guardar(c: Cita): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(c.id) },
      {
        _id: oid(c.id),
        pacienteId: oid(c.pacienteId),
        medicoId: oid(c.medicoId),
        agendadaPorUsuarioId: oid(c.agendadaPorUsuarioId),
        inicio: c.inicio,
        fin: c.fin,
        modalidad: c.modalidad,
        motivo: c.motivo,
        estado: c.estado,
        ocupaFranja: c.ocupaFranja,
        monto: aDecimal128(c.monto),
        moneda: c.moneda,
        politicaAplicada: {
          tipo: c.politicaAplicada.tipo,
          horasMinimasAviso: c.politicaAplicada.horasMinimasAviso,
          porcentajePenalizacion: c.politicaAplicada.porcentajePenalizacion,
        },
        citaOrigenId: oidOpcional(c.citaOrigenId),
        referenciaId: oidOpcional(c.referenciaId),
        propuestaPor: c.propuestaPor,
        propuestaExpiraEn: c.propuestaExpiraEn,
        canceladaPor: c.canceladaPor,
        motivoCancelacion: c.motivoCancelacion,
        canceladaEn: c.canceladaEn,
        atendidaEn: c.atendidaEn,
        creadaEn: c.creadaEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<Cita | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async existeSolapamiento(medicoId: string, inicio: Date, fin: Date, excluirId?: string): Promise<boolean> {
    const filtro: FilterQuery<CitaDoc> = { medicoId: oid(medicoId), ocupaFranja: true, inicio: { $lt: fin }, fin: { $gt: inicio } };
    if (excluirId) filtro._id = { $ne: oid(excluirId) };
    return (await this.modelo.countDocuments(filtro)) > 0;
  }

  async buscarOcupadas(medicoId: string, desde: Date, hasta: Date): Promise<Cita[]> {
    const docs = await this.modelo
      .find({ medicoId: oid(medicoId), ocupaFranja: true, inicio: { $lt: hasta }, fin: { $gt: desde } })
      .lean();
    return docs.map((d) => this.aDominio(d));
  }

  async listarPorPacientes(pacienteIds: string[], filtros: FiltrosCitas): Promise<Cita[]> {
    return this.listar({ pacienteId: { $in: pacienteIds.map(oid) } }, filtros);
  }

  async listarPorMedico(medicoId: string, filtros: FiltrosCitas): Promise<Cita[]> {
    return this.listar({ medicoId: oid(medicoId) }, filtros);
  }

  async buscarPropuestasVencidas(ahora: Date): Promise<Cita[]> {
    const docs = await this.modelo.find({ estado: EstadoCita.PENDIENTE_ACEPTACION, propuestaExpiraEn: { $lte: ahora } }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async existeAtendida(pacienteId: string, medicoId: string): Promise<boolean> {
    return (await this.modelo.countDocuments({ pacienteId: oid(pacienteId), medicoId: oid(medicoId), estado: EstadoCita.ATENDIDA })) > 0;
  }

  private async listar(base: FilterQuery<CitaDoc>, f: FiltrosCitas): Promise<Cita[]> {
    const filtro: FilterQuery<CitaDoc> = { ...base };
    if (f.estados?.length) filtro.estado = { $in: f.estados };
    if (f.desde || f.hasta) {
      const rango: { $gte?: Date; $lte?: Date } = {};
      if (f.desde) rango.$gte = f.desde;
      if (f.hasta) rango.$lte = f.hasta;
      filtro.inicio = rango;
    }
    const docs = await this.modelo.find(filtro).sort({ inicio: -1 }).limit(200).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: CitaDoc): Cita {
    return new Cita({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      agendadaPorUsuarioId: str(d.agendadaPorUsuarioId),
      inicio: d.inicio,
      fin: d.fin,
      modalidad: d.modalidad as Modalidad,
      motivo: d.motivo,
      estado: d.estado as EstadoCita,
      monto: deDecimal128(d.monto),
      moneda: d.moneda,
      politicaAplicada: new PoliticaCancelacion(
        d.politicaAplicada.tipo as TipoPolitica,
        d.politicaAplicada.horasMinimasAviso,
        d.politicaAplicada.porcentajePenalizacion,
      ),
      citaOrigenId: strOpcional(d.citaOrigenId),
      referenciaId: strOpcional(d.referenciaId),
      propuestaPor: d.propuestaPor as Parte | undefined,
      propuestaExpiraEn: d.propuestaExpiraEn,
      canceladaPor: d.canceladaPor as Cancelador | undefined,
      motivoCancelacion: d.motivoCancelacion,
      canceladaEn: d.canceladaEn,
      atendidaEn: d.atendidaEn,
      creadaEn: d.creadaEn,
    });
  }
}
