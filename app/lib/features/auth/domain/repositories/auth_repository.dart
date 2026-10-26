import '../entities/usuario_sesion.dart';

/// Contrato del repositorio de autenticación (capa de Dominio, sin Flutter ni Dio).
abstract class AuthRepository {
  Future<UsuarioSesion> iniciarSesion(String email, String password);
  Future<UsuarioSesion> registrarPaciente(DatosRegistroPaciente datos);
  Future<UsuarioSesion> registrarMedico(DatosRegistroMedico datos);
  Future<UsuarioSesion?> restaurarSesion();
  Future<void> cerrarSesion();
  Stream<void> get sesionExpirada;
}
