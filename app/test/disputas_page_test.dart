import 'package:bewell/features/disputas/domain/entities/disputa.dart';
import 'package:bewell/features/disputas/domain/repositories/disputas_repository.dart';
import 'package:bewell/features/disputas/domain/usecases/disputas_usecases.dart';
import 'package:bewell/features/disputas/presentation/cubit/disputas_cubit.dart';
import 'package:bewell/features/disputas/presentation/pages/disputas_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _disputa = Disputa(
  pagoId: 'p1',
  citaId: 'c1',
  monto: 50,
  moneda: 'USD',
  estado: 'EN_DISPUTA',
  motivo: 'El médico no se conectó',
  pacienteNombre: 'Sofía Morales',
  medicoNombre: 'Dr. Ruiz',
);

class _RepoFalso implements DisputasRepository {
  _RepoFalso(this.disputas);
  List<Disputa> disputas;
  final resueltas = <String>[];

  @override
  Future<List<Disputa>> listar() async => disputas;

  @override
  Future<Disputa> resolver(String pagoId, AccionDisputa accion, {String? nota}) async {
    resueltas.add('$pagoId:${accion.codigo}:${nota ?? ''}');
    return _disputa;
  }
}

Future<DisputasCubit> _montar(WidgetTester tester, _RepoFalso repo) async {
  final cubit = DisputasCubit(GestionarDisputas(repo));
  await cubit.cargar();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: BlocProvider.value(value: cubit, child: const DisputasVista())),
  ));
  await tester.pump();
  return cubit;
}

void main() {
  testWidgets('muestra cada disputa con el motivo, el monto y las dos acciones', (tester) async {
    await _montar(tester, _RepoFalso([_disputa]));
    expect(find.text('El médico no se conectó'), findsOneWidget);
    expect(find.text('Sofía Morales · Dr. Ruiz'), findsOneWidget);
    expect(find.text('Liberar al médico'), findsOneWidget);
    expect(find.text('Reembolsar al paciente'), findsOneWidget);
  });

  testWidgets('sin disputas muestra el estado vacío', (tester) async {
    await _montar(tester, _RepoFalso([]));
    expect(find.text('No hay disputas abiertas'), findsOneWidget);
  });

  testWidgets('reembolsar pide confirmación y nota, resuelve y quita la disputa', (tester) async {
    final repo = _RepoFalso([_disputa]);
    await _montar(tester, repo);
    await tester.tap(find.text('Reembolsar al paciente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Se devolverán'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reembolsar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'No hubo consulta');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.resueltas, ['p1:REEMBOLSAR:No hubo consulta']);
    expect(find.text('No hay disputas abiertas'), findsOneWidget);
  });

  testWidgets('si el administrador vuelve atrás no se resuelve nada', (tester) async {
    final repo = _RepoFalso([_disputa]);
    await _montar(tester, repo);
    await tester.tap(find.text('Liberar al médico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repo.resueltas, isEmpty);
    expect(find.text('El médico no se conectó'), findsOneWidget);
  });

  test('el cubit quita la disputa resuelta de la lista', () async {
    final cubit = DisputasCubit(GestionarDisputas(_RepoFalso([_disputa])));
    await cubit.cargar();
    expect(await cubit.resolver(_disputa, AccionDisputa.liberar), isNull);
    expect(cubit.state.datosOpcional, isEmpty);
  });
}
