import '../../domain/entities/perfil.dart';
import '../../domain/repositories/perfiles_repository.dart';
import '../datasources/perfiles_remote_data_source.dart';

class PerfilesRepositoryImpl implements PerfilesRepository {
  const PerfilesRepositoryImpl(this._remoto);
  final PerfilesRemoteDataSource _remoto;

  @override
  Future<List<Perfil>> listar() async => (await _remoto.listar()).map(PerfilMapper.desdeJson).toList();

  @override
  Future<Perfil> crearFamiliar(NuevoPerfil datos) async => PerfilMapper.desdeJson(await _remoto.crear(datos));
}
