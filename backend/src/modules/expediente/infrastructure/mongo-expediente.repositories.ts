import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { CategoriaClinica, TipoEvento } from '../domain/categoria-clinica';
import { EventoClinico } from '../domain/evento-clinico';
import { ExpedienteClinico } from '../domain/expediente-clinico';
import { OrigenPermiso, PermisoAcceso } from '../domain/permiso-acceso';
import { EstadoReferencia, ReferenciaEspecialista } from '../domain/referencia-especialista';
import {
  EventoClinicoRepository,
  ExpedienteRepository,
  Paginacion,
  PermisoAccesoRepository,
  ReferenciaRepository,
} from '../domain/repositorios';
import { EventoClinicoDoc, ExpedienteDoc, PermisoAccesoDoc, ReferenciaDoc } from './expediente.schemas';

@Injectable()
export class MongoExpedienteRepository extends ExpedienteRepository {
  constructor(
    @InjectModel(ExpedienteDoc.name) private readonly modelo: Model<ExpedienteDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(e: ExpedienteClinico): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(e.id) },
      { _id: oid(e.id), pacienteId: oid(e.pacienteId), antecedentes: this.cifrador.cifrarLista(e.antecedentes), actualizadoEn: e.actualizadoEn },
      { upsert: true },
    );
  }

  async buscarPorPaciente(pacienteId: string): Promise<ExpedienteClinico | null> {
    const d = await this.modelo.findOne({ pacienteId: oid(pacienteId) }).lean();
    return d ? new ExpedienteClinico(str(d._id), str(d.pacienteId), this.cifrador.descifrarLista(d.antecedentes), d.actualizadoEn) : null;
  }
}

@Injectable()
export class MongoPermisoAccesoRepository extends PermisoAccesoRepository {
  constructor(@InjectModel(PermisoAccesoDoc.name) private readonly modelo: Model<PermisoAccesoDoc>) {
    super();
  }

  async guardar(p: PermisoAcceso): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(p.id) },
      {
        _id: oid(p.id),
        expedienteId: oid(p.expedienteId),
        pacienteId: oid(p.pacienteId),
        medicoId: oid(p.medicoId),
        categoriasPermitidas: p.categoriasPermitidas,
        escritura: p.escritura,
        validoHasta: p.validoHasta,
        revocado: p.revocado,
        revocadoEn: p.revocadoEn,
        otorgadoPorUsuarioId: oid(p.otorgadoPorUsuarioId),
        origen: p.origen,
        creadoEn: p.creadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<PermisoAcceso | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarVigentes(pacienteId: string, medicoId: string, fecha: Date): Promise<PermisoAcceso[]> {
    const docs = await this.modelo
      .find({ pacienteId: oid(pacienteId), medicoId: oid(medicoId), revocado: false, validoHasta: { $gt: fecha } })
      .lean();
    return docs.map((d) => this.aDominio(d));
  }

  async listarPorPaciente(pacienteId: string): Promise<PermisoAcceso[]> {
    return (await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ creadoEn: -1 }).lean()).map((d) => this.aDominio(d));
  }

  async listarVigentesPorMedico(medicoId: string, fecha: Date): Promise<PermisoAcceso[]> {
    const docs = await this.modelo.find({ medicoId: oid(medicoId), revocado: false, validoHasta: { $gt: fecha } }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: PermisoAccesoDoc): PermisoAcceso {
    return new PermisoAcceso({
      id: str(d._id),
      expedienteId: str(d.expedienteId),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      categoriasPermitidas: d.categoriasPermitidas as CategoriaClinica[],
      escritura: d.escritura,
      validoHasta: d.validoHasta,
      revocado: d.revocado,
      revocadoEn: d.revocadoEn,
      otorgadoPorUsuarioId: str(d.otorgadoPorUsuarioId),
      origen: d.origen as OrigenPermiso,
      creadoEn: d.creadoEn,
    });
  }
}

@Injectable()
export class MongoEventoClinicoRepository extends EventoClinicoRepository {
  constructor(
    @InjectModel(EventoClinicoDoc.name) private readonly modelo: Model<EventoClinicoDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(e: EventoClinico): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(e.id) },
      {
        _id: oid(e.id),
        expedienteId: oid(e.expedienteId),
        pacienteId: oid(e.pacienteId),
        tipo: e.tipo,
        categoria: e.categoria,
        fecha: e.fecha,
        titulo: e.titulo,
        resumen: e.resumen ? this.cifrador.cifrar(e.resumen) : '',
        medicoId: oidOpcional(e.medicoId),
        autorUsuarioId: oidOpcional(e.autorUsuarioId),
        documentoOrigenId: oidOpcional(e.documentoOrigenId),
        detalles: e.detalles,
        creadoEn: e.creadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<EventoClinico | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPaciente(
    pacienteId: string,
    categorias: CategoriaClinica[],
    tipo: TipoEvento | undefined,
    { pagina, tamano }: Paginacion,
  ): Promise<{ items: EventoClinico[]; total: number }> {
    const filtro: FilterQuery<EventoClinicoDoc> = { pacienteId: oid(pacienteId), categoria: { $in: categorias } };
    if (tipo) filtro.tipo = tipo;
    const [docs, total] = await Promise.all([
      this.modelo.find(filtro).sort({ fecha: -1, creadoEn: -1 }).skip((pagina - 1) * tamano).limit(tamano).lean(),
      this.modelo.countDocuments(filtro),
    ]);
    return { items: docs.map((d) => this.aDominio(d)), total };
  }

  private aDominio(d: EventoClinicoDoc): EventoClinico {
    return new EventoClinico({
      id: str(d._id),
      expedienteId: str(d.expedienteId),
      pacienteId: str(d.pacienteId),
      tipo: d.tipo as TipoEvento,
      categoria: d.categoria as CategoriaClinica,
      fecha: d.fecha,
      titulo: d.titulo,
      resumen: d.resumen ? this.cifrador.descifrar(d.resumen) : '',
      medicoId: strOpcional(d.medicoId),
      autorUsuarioId: strOpcional(d.autorUsuarioId),
      documentoOrigenId: strOpcional(d.documentoOrigenId),
      detalles: d.detalles ?? {},
      creadoEn: d.creadoEn,
    });
  }
}

@Injectable()
export class MongoReferenciaRepository extends ReferenciaRepository {
  constructor(
    @InjectModel(ReferenciaDoc.name) private readonly modelo: Model<ReferenciaDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(r: ReferenciaEspecialista): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(r.id) },
      {
        _id: oid(r.id),
        pacienteId: oid(r.pacienteId),
        medicoOrigenId: oid(r.medicoOrigenId),
        medicoDestinoId: oid(r.medicoDestinoId),
        especialidadDestino: r.especialidadDestino,
        motivo: this.cifrador.cifrar(r.motivo),
        estado: r.estado,
        fecha: r.fecha,
        respondidaEn: r.respondidaEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<ReferenciaEspecialista | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPacientes(pacienteIds: string[]): Promise<ReferenciaEspecialista[]> {
    const docs = await this.modelo.find({ pacienteId: { $in: pacienteIds.map(oid) } }).sort({ fecha: -1 }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async listarPorMedico(medicoId: string): Promise<ReferenciaEspecialista[]> {
    const id = oid(medicoId);
    const docs = await this.modelo.find({ $or: [{ medicoOrigenId: id }, { medicoDestinoId: id }] }).sort({ fecha: -1 }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: ReferenciaDoc): ReferenciaEspecialista {
    return new ReferenciaEspecialista({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      medicoOrigenId: str(d.medicoOrigenId),
      medicoDestinoId: str(d.medicoDestinoId),
      especialidadDestino: d.especialidadDestino,
      motivo: this.cifrador.descifrar(d.motivo),
      estado: d.estado as EstadoReferencia,
      fecha: d.fecha,
      respondidaEn: d.respondidaEn,
    });
  }
}
