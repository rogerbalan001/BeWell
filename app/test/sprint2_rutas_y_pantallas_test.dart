import 'package:bewell/core/di/injector.dart';
import 'package:bewell/core/router/app_router.dart';
import 'package:bewell/features/auth/presentation/cubit/sesion_cubit.dart';
import 'package:bewell/features/disputas/presentation/cubit/disputas_cubit.dart';
import 'package:bewell/features/examenes/domain/entities/examen.dart';
import 'package:bewell/features/examenes/domain/repositories/examenes_repository.dart';
import 'package:bewell/features/examenes/domain/usecases/examenes_usecases.dart';
import 'package:bewell/features/examenes/presentation/cubit/examenes_cubit.dart';
import 'package:bewell/features/examenes/presentation/pages/ordenes_examenes_page.dart';
import 'package:bewell/features/expediente/domain/entities/expediente.dart';
import 'package:bewell/features/expediente/presentation/cubit/expediente_cubits.dart';
import 'package:bewell/features/expediente/presentation/widgets/linea_tiempo.dart';
import 'package:bewell/features/recordatorios/domain/entities/recordatorio.dart';
import 'package:bewell/features/recordatorios/domain/repositories/recordatorios_repository.dart';
import 'package:bewell/features/recordatorios/domain/usecases/recordatorios_usecases.dart';
import 'package:bewell/features/recordatorios/presentation/cubit/recordatorios_cubit.dart';
import 'package:bewell/features/recordatorios/presentation/pages/recordatorios_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Rutas completas de la app (une las rutas anidadas con las de su padre).
List<String> _rutas(List<RouteBase> rutas, [String padre = '']) => [
      for (final r in rutas) ...[
        if (r is GoRoute) r.path.startsWith('/') ? r.path : '$padre/${r.path}',
        ..._rutas(r.routes, r is GoRoute ? (r.path.startsWith('/') ? r.path : '$padre/${r.path}') : padre),
      ],
    ];

class _RecordatoriosFalso implements RecordatoriosRepository {
  PreferenciasRecordatorio preferenciasGuardadas = const PreferenciasRecordatorio(citas: true, medicamentos: true, examenes: true);
  @override
  Future<PreferenciasRecordatorio> preferencias() async => preferenciasGuardadas;
  @override
  Future<PreferenciasRecordatorio> actualizar(PreferenciasRecordatorio p) async => preferenciasGuardadas = p;
  @override
  Future<List<Recordatorio>> proximos({String? pacienteId}) async => [
        Recordatorio(
          tipo: TipoRecordatorio.citas,
          pacienteId: 'p1',
          pacienteNombre: 'Sofía',
          programadoPara: DateTime(2026, 11, 6, 9),
          titulo: 'Tu cita es mañana',
          mensaje: 'Con la Dra. Soto a las 9:00 am',
        ),
      ];
}

class _ExamenesFalso implements ExamenesRepository {
  final anuladas = <String>[];
  @override
  Future<List<SolicitudExamen>> solicitudes({String? pacienteId}) async => [
        SolicitudExamen(
          id: 'o1',
          pacienteId: 'p1',
          examenes: const ['Perfil lipídico'],
          indicaciones: '',
          estado: anuladas.contains('o1') ? 'ANULADA' : 'PENDIENTE',
          creadaEn: DateTime(2026, 11, 1),
        ),
      ];
  @override
  Future<SolicitudExamen> anularSolicitud(String solicitudId, String motivo) async {
    anuladas.add(solicitudId);
    return (await solicitudes()).first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventoClinico _evento(String tipo, {Map<String, String> detalles = const {}}) => EventoClinico(
      id: tipo,
      tipo: tipo,
      categoria: 'LABORATORIOS',
      fecha: DateTime(2026, 10, 20),
      titulo: tipo == 'RECETA' ? 'Récipe de loratadina' : 'Orden de exámenes (1)',
      resumen: 'Detalle del evento',
      detalles: detalles,
      autoReportado: false,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() async => sl.reset());

  test('todas las pantallas del Sprint 2 y 3 tienen ruta y dependencias registradas', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    configurarDependencias();
    final router = crearRouter(sl<SesionCubit>());
    final rutas = _rutas(router.configuration.routes);
    expect(
      rutas,
      containsAll(<String>['/recordatorios', '/citas/:id', '/examenes/:id/revisar', '/medico/pacientes/:pacienteId/examenes', '/admin/disputas']),
    );
    expect(sl<RecordatoriosCubit>(), isA<RecordatoriosCubit>());
    expect(sl<OrdenesExamenesCubit>(), isA<OrdenesExamenesCubit>());
    expect(sl<ExpedienteCubit>(), isA<ExpedienteCubit>());
    expect(sl<DisputasCubit>(), isA<DisputasCubit>());
    router.dispose();
  });

  testWidgets('Recordatorios: muestra los tres interruptores y guarda el cambio', (tester) async {
    final repo = _RecordatoriosFalso();
    sl.registerFactory(() => RecordatoriosCubit(GestionarRecordatorios(repo)));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RecordatoriosPage())));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    expect(find.text('Tu cita es mañana'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile).at(1));
    await tester.pumpAndSettle();
    expect(repo.preferenciasGuardadas.medicamentos, isFalse);
    expect(repo.preferenciasGuardadas.citas, isTrue);
  });

  testWidgets('Línea de tiempo: el titular abre el récipe desde el detalle; la orden muestra su estado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LineaTiempo(esTitular: true, eventos: [
            _evento('RECETA'),
            _evento('SOLICITUD_EXAMEN', detalles: const {'estado': 'COMPLETADA'}),
          ]),
        ),
      ),
    ));
    expect(find.text('Resultados cargados'), findsOneWidget);
    await tester.tap(find.text('Récipe de loratadina'));
    await tester.pumpAndSettle();
    expect(find.text('Ver récipe'), findsOneWidget);
  });

  testWidgets('Línea de tiempo: el médico no ve el botón al documento del paciente', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LineaTiempo(eventos: [_evento('RECETA')])))));
    await tester.tap(find.text('Récipe de loratadina'));
    await tester.pumpAndSettle();
    expect(find.text('Ver récipe'), findsNothing);
  });

  testWidgets('Órdenes de exámenes: el médico anula una orden pendiente con motivo', (tester) async {
    final repo = _ExamenesFalso();
    sl.registerFactory(() => OrdenesExamenesCubit(GestionarOrdenesExamen(repo)));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: OrdenesExamenesPage(pacienteId: 'p1', pacienteNombre: 'Sofía'))));
    await tester.pumpAndSettle();
    expect(find.text('Perfil lipídico'), findsOneWidget);
    await tester.tap(find.text('Anular orden'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Se indicó por error');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
    await tester.pumpAndSettle();
    expect(repo.anuladas, ['o1']);
    expect(find.text('Anular orden'), findsNothing);
  });
}
