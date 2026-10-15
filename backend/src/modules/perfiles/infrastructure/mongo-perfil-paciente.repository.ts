import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CifradorCampos } from '../../../shared/application/cifrador-campos';
import { oid, str } from '../../../shared/infrastructure/mongo/mongo.utils';
import { PerfilPaciente, Sexo } from '../domain/perfil-paciente';
import { PerfilPacienteRepository } from '../domain/perfil-paciente.repository';
import { PerfilPacienteDoc } from './perfil-paciente.schema';

@Injectable()
export class MongoPerfilPacienteRepository extends PerfilPacienteRepository {
  constructor(
    @InjectModel(PerfilPacienteDoc.name) private readonly modelo: Model<PerfilPacienteDoc>,
    private readonly cifrador: CifradorCampos,
  ) {
    super();
  }

  async guardar(p: PerfilPaciente): Promise<void> {
    await this.modelo.replaceOne(
      { _id: oid(p.id) },
      {
        _id: oid(p.id),
        titularUsuarioId: oid(p.titularUsuarioId),
        parentescoConTitular: p.parentescoConTitular,
        nombres: p.nombres,
        apellidos: p.apellidos,
        cedulaCifrada: this.cifrador.cifrarOpcional(p.cedula),
        cedulaHuella: p.cedula ? this.cifrador.huella(p.cedula) : undefined,
        fechaNacimiento: p.fechaNacimiento,
        sexo: p.sexo,
        creadoEn: p.creadoEn,
      },
      { upsert: true },
    );
  }

  async buscarPorId(id: string): Promise<PerfilPaciente | null> {
    const doc = await this.modelo.findById(oid(id)).lean();
    return doc ? this.aDominio(doc) : null;
  }

  async buscarPorIds(ids: string[]): Promise<PerfilPaciente[]> {
    const docs = await this.modelo.find({ _id: { $in: ids.map(oid) } }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  async buscarPorTitular(usuarioId: string): Promise<PerfilPaciente[]> {
    const docs = await this.modelo.find({ titularUsuarioId: oid(usuarioId) }).sort({ creadoEn: 1 }).lean();
    return docs.map((d) => this.aDominio(d));
  }

  private aDominio(d: PerfilPacienteDoc): PerfilPaciente {
    return new PerfilPaciente({
      id: str(d._id),
      titularUsuarioId: str(d.titularUsuarioId),
      parentescoConTitular: d.parentescoConTitular,
      nombres: d.nombres,
      apellidos: d.apellidos,
      cedula: this.cifrador.descifrarOpcional(d.cedulaCifrada),
      fechaNacimiento: d.fechaNacimiento,
      sexo: d.sexo as Sexo,
      creadoEn: d.creadoEn,
    });
  }
}
