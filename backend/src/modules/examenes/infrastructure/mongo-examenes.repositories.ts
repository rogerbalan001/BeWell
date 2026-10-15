import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { EstadoExtraccion, ExamenMedico, ResultadoAnalito } from '../domain/examen-medico';
import { ExamenRepository, SolicitudExamenRepository } from '../domain/repositorios';
import { EstadoSolicitud, SolicitudExamen } from '../domain/solicitud-examen';
import { ExamenDoc, SolicitudExamenDoc } from './examenes.schemas';

@Injectable()
export class MongoExamenRepository extends ExamenRepository {
  constructor(
    @InjectModel(ExamenDoc.name) private readonly modelo: Model<ExamenDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(e: ExamenMedico): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(e.id) },
      {
        _id: oid(e.id),
        pacienteId: oid(e.pacienteId),
        solicitudId: oidOpcional(e.solicitudId),
        titulo: e.titulo,
        fechaExamen: e.fechaExamen,
        archivoRef: e.archivoRef,
        tipoMime: e.tipoMime,
        nombreArchivo: e.nombreArchivo,
        tamanoBytes: e.tamanoBytes,
        estadoExtraccion: e.estadoExtraccion,
        resultadosCifrados: e.resultados.length ? this.cifrador.cifrar(JSON.stringify(e.resultados)) : undefined,
        cargadoPorUsuarioId: oid(e.cargadoPorUsuarioId),
        cargadoEn: e.cargadoEn,
        validadoPorMedicoId: oidOpcional(e.validadoPorMedicoId),
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<ExamenMedico | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPaciente(pacienteId: string): Promise<ExamenMedico[]> {
    return (await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ cargadoEn: -1 }).lean()).map((d) => this.aDominio(d));
  }

  private aDominio(d: ExamenDoc): ExamenMedico {
    return new ExamenMedico({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      solicitudId: strOpcional(d.solicitudId),
      titulo: d.titulo,
      fechaExamen: d.fechaExamen,
      archivoRef: d.archivoRef,
      tipoMime: d.tipoMime,
      nombreArchivo: d.nombreArchivo,
      tamanoBytes: d.tamanoBytes,
      estadoExtraccion: d.estadoExtraccion as EstadoExtraccion,
      resultados: d.resultadosCifrados ? (JSON.parse(this.cifrador.descifrar(d.resultadosCifrados)) as ResultadoAnalito[]) : [],
      cargadoPorUsuarioId: str(d.cargadoPorUsuarioId),
      cargadoEn: d.cargadoEn,
      validadoPorMedicoId: strOpcional(d.validadoPorMedicoId),
    });
  }
}

@Injectable()
export class MongoSolicitudExamenRepository extends SolicitudExamenRepository {
  constructor(
    @InjectModel(SolicitudExamenDoc.name) private readonly modelo: Model<SolicitudExamenDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(s: SolicitudExamen): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(s.id) },
      {
        _id: oid(s.id),
        pacienteId: oid(s.pacienteId),
        medicoId: oid(s.medicoId),
        citaId: oidOpcional(s.citaId),
        examenes: s.examenes,
        indicaciones: s.indicaciones ? this.cifrador.cifrar(s.indicaciones) : '',
        estado: s.estado,
        examenResultadoIds: s.examenResultadoIds.map(oid),
        creadaEn: s.creadaEn,
        completadaEn: s.completadaEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<SolicitudExamen | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPaciente(pacienteId: string): Promise<SolicitudExamen[]> {
    return (await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ creadaEn: -1 }).lean()).map((d) => this.aDominio(d));
  }

  async listarPorMedico(medicoId: string): Promise<SolicitudExamen[]> {
    return (await this.modelo.find({ medicoId: oid(medicoId) }).sort({ creadaEn: -1 }).limit(200).lean()).map((d) => this.aDominio(d));
  }

  private aDominio(d: SolicitudExamenDoc): SolicitudExamen {
    return new SolicitudExamen({
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      citaId: strOpcional(d.citaId),
      examenes: d.examenes,
      indicaciones: d.indicaciones ? this.cifrador.descifrar(d.indicaciones) : '',
      estado: d.estado as EstadoSolicitud,
      examenResultadoIds: (d.examenResultadoIds ?? []).map(str),
      creadaEn: d.creadaEn,
      completadaEn: d.completadaEn,
    });
  }
}
