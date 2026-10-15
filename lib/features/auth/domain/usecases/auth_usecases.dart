import '../entities/usuario_sesion.dart';
import '../repositories/auth_repository.dart';

class IniciarSesion {
  const IniciarSesion(this._repo);
  final AuthRepository _repo;
  Future<UsuarioSesion> call(String email, String password) => _repo.iniciarSesion(email.trim(), password);
}

class RegistrarPaciente {
  const RegistrarPaciente(this._repo);
  final AuthRepository _repo;
  Future<UsuarioSesion> call(DatosRegistroPaciente datos) => _repo.registrarPaciente(datos);
}

class RegistrarMedico {
  const RegistrarMedico(this._repo);
  final AuthRepository _repo;
  Future<UsuarioSesion> call(DatosRegistroMedico datos) => _repo.registrarMedico(datos);
}

class RestaurarSesion {
  const RestaurarSesion(this._repo);
  final AuthRepository _repo;
  Future<UsuarioSesion?> call() => _repo.restaurarSesion();
}

class CerrarSesion {
  const CerrarSesion(this._repo);
  final AuthRepository _repo;
  Future<void> call() => _repo.cerrarSesion();
}
