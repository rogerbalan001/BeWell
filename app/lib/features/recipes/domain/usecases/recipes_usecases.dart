import '../entities/recipe.dart';
import '../repositories/recipes_repository.dart';

class ListarRecipes {
  const ListarRecipes(this._r);
  final RecipesRepository _r;
  Future<List<Recipe>> dePaciente(String pacienteId) => _r.dePaciente(pacienteId);
  Future<List<Recipe>> emitidos() => _r.emitidos();
}

/// HU médico: emitir récipes digitales con firma y código verificable.
class EmitirRecipe {
  const EmitirRecipe(this._r);
  final RecipesRepository _r;
  Future<Recipe> call({required String citaId, required List<ItemRecipe> items, String? diagnostico, int validoDias = 30}) =>
      _r.emitir(citaId: citaId, items: items, diagnostico: diagnostico, validoDias: validoDias);
  Future<Recipe> anular(String id, String motivo) => _r.anular(id, motivo);
}

/// Una farmacia valida el récipe con el código o escaneando el QR (sin iniciar sesión).
class VerificarRecipe {
  const VerificarRecipe(this._r);
  final RecipesRepository _r;
  Future<VerificacionRecipe> call(String codigo) => _r.verificar(codigo.trim().toUpperCase());
}
