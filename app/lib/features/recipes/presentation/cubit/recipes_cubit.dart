import '../../../../core/estado/recurso.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/recipes_usecases.dart';

class RecipesCubit extends RecursoCubit<List<Recipe>> {
  RecipesCubit(this._listar);
  final ListarRecipes _listar;
  Future<void> dePaciente(String pacienteId) => ejecutar(() => _listar.dePaciente(pacienteId));
  Future<void> emitidos({bool silencioso = false}) => ejecutar(_listar.emitidos, silencioso: silencioso);
}
