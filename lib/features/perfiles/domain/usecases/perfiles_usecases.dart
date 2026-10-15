import '../entities/perfil.dart';
import '../repositories/perfiles_repository.dart';

class ListarPerfiles {
  const ListarPerfiles(this._repo);
  final PerfilesRepository _repo;
  Future<List<Perfil>> call() => _repo.listar();
}

class CrearPerfilFamiliar {
  const CrearPerfilFamiliar(this._repo);
  final PerfilesRepository _repo;
  Future<Perfil> call(NuevoPerfil datos) => _repo.crearFamiliar(datos);
}
