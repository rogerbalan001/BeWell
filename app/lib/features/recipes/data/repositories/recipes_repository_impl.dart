import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../datasources/recipes_remote_data_source.dart';

class RecipesRepositoryImpl implements RecipesRepository {
  const RecipesRepositoryImpl(this._r);
  final RecipesRemoteDataSource _r;

  @override
  Future<List<Recipe>> dePaciente(String pacienteId) async => (await _r.dePaciente(pacienteId)).map(RecipeMapper.recipe).toList();

  @override
  Future<List<Recipe>> emitidos() async => (await _r.emitidos()).map(RecipeMapper.recipe).toList();

  @override
  Future<Recipe> emitir({required String citaId, required List<ItemRecipe> items, String? diagnostico, int validoDias = 30}) async =>
      RecipeMapper.recipe(await _r.emitir({
        'citaId': citaId,
        'items': items.map((i) => i.aJson()).toList(),
        if (diagnostico != null && diagnostico.isNotEmpty) 'diagnostico': diagnostico,
        'validoDias': validoDias,
      }));

  @override
  Future<Recipe> anular(String id, String motivo) async => RecipeMapper.recipe(await _r.anular(id, motivo));

  @override
  Future<VerificacionRecipe> verificar(String codigo) async => RecipeMapper.verificacion(await _r.verificar(codigo));
}
