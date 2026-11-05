import 'package:bewell/core/di/injector.dart';
import 'package:bewell/features/recipes/domain/entities/recipe.dart';
import 'package:bewell/features/recipes/domain/repositories/recipes_repository.dart';
import 'package:bewell/features/recipes/domain/usecases/recipes_usecases.dart';
import 'package:bewell/features/recipes/presentation/pages/verificar_recipe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _items = [ItemRecipe(medicamento: 'Loratadina', presentacion: 'Tabletas 10 mg', dosis: '1 tableta', frecuencia: 'cada 24 h', duracionDias: 14)];

VerificacionRecipe _encontrado({bool valido = true, bool vigente = true, String estado = 'VIGENTE', String? motivoAnulacion}) => VerificacionRecipe(
      encontrado: true,
      valido: valido,
      firmaValida: true,
      integro: true,
      vigente: vigente,
      estado: estado,
      codigo: 'RX-ABCDE-FGHJK',
      medicoNombre: 'Dr. Mateo Ruiz',
      especialidad: 'Medicina General',
      medicoVerificado: true,
      pacienteNombre: 'Sofía Morales',
      emitidoEn: DateTime(2026, 10, 1),
      validoHasta: DateTime(2026, 10, 31),
      items: _items,
      motivoAnulacion: motivoAnulacion,
    );

class _RecipesFalso implements RecipesRepository {
  _RecipesFalso(this.respuesta);
  final VerificacionRecipe respuesta;
  final consultados = <String>[];

  @override
  Future<VerificacionRecipe> verificar(String codigo) async {
    consultados.add(codigo);
    return respuesta;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_RecipesFalso> _verificar(WidgetTester tester, VerificacionRecipe respuesta, {String codigo = 'rx-abcde-fghjk'}) async {
  final repo = _RecipesFalso(respuesta);
  sl.registerLazySingleton(() => VerificarRecipe(repo));
  await tester.pumpWidget(MaterialApp(home: VerificarRecipePage(codigo: codigo)));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() async => sl.reset());

  testWidgets('un récipe válido muestra el emisor, el paciente y los medicamentos', (tester) async {
    final repo = await _verificar(tester, _encontrado());
    expect(repo.consultados, ['RX-ABCDE-FGHJK']);
    expect(find.text('Récipe válido'), findsOneWidget);
    expect(find.textContaining('Dr. Mateo Ruiz'), findsOneWidget);
    expect(find.textContaining('Sofía Morales'), findsOneWidget);
    expect(find.textContaining('Loratadina'), findsWidgets);
  });

  testWidgets('un récipe anulado no es válido y muestra el motivo', (tester) async {
    await _verificar(tester, _encontrado(valido: false, estado: 'ANULADO', motivoAnulacion: 'Error en la dosis'));
    expect(find.text('Récipe NO válido'), findsOneWidget);
    expect(find.text('El médico anuló este récipe: Error en la dosis.'), findsOneWidget);
  });

  testWidgets('un récipe vencido no es válido', (tester) async {
    await _verificar(tester, _encontrado(valido: false, vigente: false));
    expect(find.text('Récipe NO válido'), findsOneWidget);
    expect(find.text('El récipe está vencido.'), findsOneWidget);
  });

  testWidgets('un código inexistente avisa que no se despache', (tester) async {
    await _verificar(tester, const VerificacionRecipe(encontrado: false, valido: false), codigo: 'RX-NOPE');
    expect(find.text('No existe un récipe con ese código. No lo despache.'), findsOneWidget);
    expect(find.text('Récipe válido'), findsNothing);
  });
}
