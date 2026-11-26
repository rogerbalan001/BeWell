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

/// HU perfiles: al cumplir 18 años, el dependiente pide el control de su perfil y el titular lo entrega.
class ControlDePerfil {
  const ControlDePerfil(this._repo);
  final PerfilesRepository _repo;
  Future<Perfil> solicitar(String cedula, DateTime fechaNacimiento) => _repo.solicitarControl(cedula.trim(), fechaNacimiento);
  Future<Perfil> aprobar(String perfilId) => _repo.responderControl(perfilId, aprobar: true);
  Future<Perfil> rechazar(String perfilId) => _repo.responderControl(perfilId, aprobar: false);
}
