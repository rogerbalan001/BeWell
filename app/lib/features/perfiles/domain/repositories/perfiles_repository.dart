import '../entities/perfil.dart';

abstract class PerfilesRepository {
  Future<List<Perfil>> listar();
  Future<Perfil> crearFamiliar(NuevoPerfil datos);
  Future<Perfil> solicitarControl(String cedula, DateTime fechaNacimiento);
  Future<Perfil> responderControl(String perfilId, {required bool aprobar});
}
