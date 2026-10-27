import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, oidOpcional, str, strOpcional } from '../../../shared/infrastructure/mongo/mongo.utils';
import { ANTECEDENTES_VACIOS, AntecedentesClinicos, DatosAntecedentes } from '../domain/antecedentes-clinicos';
import { ConsultaClinica, ContenidoConsulta } from '../domain/consulta-clinica';
import { AntecedentesClinicosRepository, ConsultaClinicaRepository } from '../domain/repositorios';
import { AntecedentesClinicosDoc, ConsultaClinicaDoc } from './historia-clinica.schemas';

@Injectable()
export class MongoAntecedentesClinicosRepository extends AntecedentesClinicosRepository {
  constructor(
    @InjectModel(AntecedentesClinicosDoc.name) private readonly modelo: Model<AntecedentesClinicosDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(a: AntecedentesClinicos): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(a.id) },
      {
        _id: oid(a.id),
        pacienteId: oid(a.pacienteId),
        datos: this.cifrador.cifrar(JSON.stringify(a.datos)),
        actualizadoEn: a.actualizadoEn,
        actualizadoPorUsuarioId: oidOpcional(a.actualizadoPorUsuarioId),
        actualizadoPorMedicoId: oidOpcional(a.actualizadoPorMedicoId),
      },
      { upsert: true },
    );
  }

  async buscarPorPaciente(pacienteId: string): Promise<AntecedentesClinicos | null> {
    const d = await this.modelo.findOne({ pacienteId: oid(pacienteId) }).lean();
    if (!d) return null;
    const datos: DatosAntecedentes = { ...structuredClone(ANTECEDENTES_VACIOS), ...JSON.parse(this.cifrador.descifrar(d.datos)) };
    return new AntecedentesClinicos(
      str(d._id),
      str(d.pacienteId),
      datos,
      d.actualizadoEn,
      strOpcional(d.actualizadoPorUsuarioId),
      strOpcional(d.actualizadoPorMedicoId),
    );
  }
}

@Injectable()
export class MongoConsultaClinicaRepository extends ConsultaClinicaRepository {
  constructor(
    @InjectModel(ConsultaClinicaDoc.name) private readonly modelo: Model<ConsultaClinicaDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(c: ConsultaClinica): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(c.id) },
      {
        _id: oid(c.id),
        pacienteId: oid(c.pacienteId),
        medicoId: oid(c.medicoId),
        autorUsuarioId: oid(c.autorUsuarioId),
        citaId: oidOpcional(c.citaId),
        fecha: c.fecha,
        contenido: this.cifrador.cifrar(JSON.stringify(c.contenido())),
        creadaEn: c.creadaEn,
        actualizadaEn: c.actualizadaEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<ConsultaClinica | null> {
    const d = await this.modelo.findById(oid(id)).lean();
    return d ? this.aDominio(d) : null;
  }

  async buscarPorCita(citaId: string): Promise<ConsultaClinica | null> {
    const d = await this.modelo.findOne({ citaId: oid(citaId) }).lean();
    return d ? this.aDominio(d) : null;
  }

  async listarPorPaciente(pacienteId: string): Promise<ConsultaClinica[]> {
    const docs = await this.modelo.find({ pacienteId: oid(pacienteId) }).sort({ fecha: -1 }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: ConsultaClinicaDoc): ConsultaClinica {
    const contenido: ContenidoConsulta = JSON.parse(this.cifrador.descifrar(d.contenido));
    return new ConsultaClinica({
      ...contenido,
      signosVitales: contenido.signosVitales ?? {},
      listaProblemas: contenido.listaProblemas ?? [],
      id: str(d._id),
      pacienteId: str(d.pacienteId),
      medicoId: str(d.medicoId),
      autorUsuarioId: str(d.autorUsuarioId),
      citaId: strOpcional(d.citaId),
      fecha: d.fecha,
      creadaEn: d.creadaEn,
      actualizadaEn: d.actualizadaEn,
    });
  }
}
