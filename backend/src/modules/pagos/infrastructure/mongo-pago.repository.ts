import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { aDecimal128, deDecimal128, oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { EstadoPago, Pago, PROVEEDOR_SIMULADO } from '../domain/pago';
import { PagoRepository } from '../domain/pago.repository';
import { PagoDoc } from './pago.schema';

@Injectable()
export class MongoPagoRepository extends PagoRepository {
  constructor(@InjectModel(PagoDoc.name) private readonly modelo: Model<PagoDoc>) {
    super();
  }

  async guardar(p: Pago): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(p.id) },
      {
        _id: oid(p.id),
        citaId: oid(p.citaId),
        pacienteId: oid(p.pacienteId),
        medicoId: oid(p.medicoId),
        monto: aDecimal128(p.monto),
        moneda: p.moneda,
        modalidad: p.modalidad,
        estado: p.estado,
        proveedor: p.proveedor,
        referenciaPasarela: p.referenciaPasarela,
        ordenPasarela: p.ordenPasarela,
        urlAprobacion: p.urlAprobacion,
        claveIdempotencia: p.claveIdempotencia,
        liberarDespuesDe: p.liberarDespuesDe,
        montoReembolsado: aDecimal128(p.montoReembolsado),
        motivoDisputa: p.motivoDisputa,
        historial: p.historial,
        creadoEn: p.creadoEn,
        actualizadoEn: p.actualizadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<Pago | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorCita(citaId: string): Promise<Pago | null> {
    const d = await this.modelo.findOne({ citaId: oid(citaId) }).sort({ creadoEn: -1 }).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorCitas(citaIds: string[]): Promise<Pago[]> {
    return (await this.modelo.find({ citaId: { $in: citaIds.map(oid) } }).lean()).map((d) => this.aDominio(d));
  }

  async buscarPorClaveIdempotencia(clave: string): Promise<Pago | null> {
    const d = await this.modelo.findOne({ claveIdempotencia: clave }).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarListosParaLiberar(ahora: Date): Promise<Pago[]> {
    const docs = await this.modelo.find({ estado: EstadoPago.RETENIDO, liberarDespuesDe: { $lte: ahora } }).limit(200).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async buscarEnDisputa(): Promise<Pago[]> {
    return (await this.modelo.find({ estado: EstadoPago.EN_DISPUTA }).sort({ actualizadoEn: 1 }).lean()).map((d) => this.aDominio(d));
  }

  async buscarPorOrdenPasarela(orden: string): Promise<Pago | null> {
    const d = await this.modelo.findOne({ ordenPasarela: orden }).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPendientesDeAprobacion(): Promise<Pago[]> {
    const docs = await this.modelo.find({ estado: EstadoPago.PENDIENTE_APROBACION }).sort({ creadoEn: 1 }).limit(200).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: PagoDoc): Pago {
    return new Pago({
      id: str(d._id),
      citaId: str(d.citaId),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      monto: deDecimal128(d.monto),
      moneda: d.moneda,
      modalidad: d.modalidad,
      estado: d.estado as EstadoPago,
      proveedor: d.proveedor ?? PROVEEDOR_SIMULADO,
      referenciaPasarela: d.referenciaPasarela,
      ordenPasarela: d.ordenPasarela,
      urlAprobacion: d.urlAprobacion,
      claveIdempotencia: d.claveIdempotencia,
      liberarDespuesDe: d.liberarDespuesDe,
      montoReembolsado: deDecimal128(d.montoReembolsado),
      motivoDisputa: d.motivoDisputa,
      historial: (d.historial ?? []).map((h) => ({ estado: h.estado as EstadoPago, fecha: h.fecha, nota: h.nota })),
      creadoEn: d.creadoEn,
      actualizadoEn: d.actualizadoEn,
    });
  }
}
