import '../entities/recipe.dart';

abstract class RecipesRepository {
  Future<List<Recipe>> dePaciente(String pacienteId);
  Future<List<Recipe>> emitidos();
  Future<Recipe> emitir({required String citaId, required List<ItemRecipe> items, String? diagnostico, int validoDias = 30});
  Future<Recipe> anular(String id, String motivo);
  Future<VerificacionRecipe> verificar(String codigo);
}
