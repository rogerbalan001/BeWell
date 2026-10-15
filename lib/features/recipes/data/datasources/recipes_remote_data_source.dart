import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/recipe.dart';

class RecipesRemoteDataSource {
  const RecipesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> dePaciente(String id) async => listaDeMapas(await _api.get('/recipes', query: {'pacienteId': id}));
  Future<List<Map<String, dynamic>>> emitidos() async => listaDeMapas(await _api.get('/recipes/emitidos'));
  Future<Map<String, dynamic>> emitir(Map<String, dynamic> d) async => mapa(await _api.post('/recipes', data: d));
  Future<Map<String, dynamic>> anular(String id, String motivo) async => mapa(await _api.post('/recipes/$id/anular', data: {'motivo': motivo}));
  Future<Map<String, dynamic>> verificar(String codigo) async => mapa(await _api.get('/recipes/verificar/${Uri.encodeComponent(codigo)}'));
}

class RecipeMapper {
  static ItemRecipe item(Map<String, dynamic> j) => ItemRecipe(
        medicamento: j['medicamento'] as String,
        presentacion: j['presentacion'] as String? ?? '',
        dosis: j['dosis'] as String,
        frecuencia: j['frecuencia'] as String,
        duracionDias: (j['duracionDias'] as num).toInt(),
        indicaciones: textoOpcional(j['indicaciones']),
      );

  static Recipe recipe(Map<String, dynamic> j) {
    final m = mapa(j['medico']);
    final p = mapa(j['paciente']);
    return Recipe(
      id: j['id'] as String,
      codigo: j['codigoVerificacion'] as String,
      urlVerificacion: j['urlVerificacion'] as String,
      estado: j['estado'] as String,
      emitidoEn: fecha(j['emitidoEn']),
      validoHasta: fecha(j['validoHasta']),
      items: listaDeMapas(j['items']).map(item).toList(),
      hash: j['hashContenido'] as String? ?? '',
      algoritmo: j['algoritmo'] as String? ?? '',
      medicoNombre: m['nombreCompleto'] as String? ?? '',
      especialidad: m['especialidad'] as String? ?? '',
      pacienteNombre: p['nombreCompleto'] as String? ?? '',
      diagnostico: textoOpcional(j['diagnostico']),
      motivoAnulacion: textoOpcional(j['motivoAnulacion']),
    );
  }

  static VerificacionRecipe verificacion(Map<String, dynamic> j) {
    if (j['encontrado'] != true) return const VerificacionRecipe(encontrado: false, valido: false);
    final m = mapa(j['medico']);
    final p = mapa(j['paciente']);
    return VerificacionRecipe(
      encontrado: true,
      valido: j['valido'] as bool? ?? false,
      firmaValida: j['firmaValida'] as bool? ?? false,
      integro: j['integro'] as bool? ?? false,
      vigente: j['vigente'] as bool? ?? false,
      estado: textoOpcional(j['estado']),
      codigo: textoOpcional(j['codigoVerificacion']),
      emitidoEn: fechaOpcional(j['emitidoEn']),
      validoHasta: fechaOpcional(j['validoHasta']),
      medicoNombre: textoOpcional(m['nombreCompleto']),
      especialidad: textoOpcional(m['especialidad']),
      medicoVerificado: m['verificado'] as bool? ?? false,
      colegiatura: textoOpcional(m['colegiatura']),
      pacienteNombre: textoOpcional(p['nombreCompleto']),
      pacienteCedula: textoOpcional(p['cedula']),
      items: listaDeMapas(j['items']).map(item).toList(),
      algoritmo: textoOpcional(j['algoritmo']),
      hash: textoOpcional(j['hashContenido']),
      motivoAnulacion: textoOpcional(j['motivoAnulacion']),
    );
  }
}
