import '../entities/perfil.dart';

abstract class PerfilesRepository {
  Future<List<Perfil>> listar();
  Future<Perfil> crearFamiliar(NuevoPerfil datos);
}
