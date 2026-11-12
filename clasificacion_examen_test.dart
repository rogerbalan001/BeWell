import 'package:bewell/features/examenes/data/datasources/examenes_remote_data_source.dart';
import 'package:bewell/features/examenes/domain/entities/examen.dart';
import 'package:bewell/features/examenes/presentation/pages/subir_examen_page.dart';
import 'package:bewell/features/examenes/presentation/widgets/selector_clasificacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> examenJson({Map<String, dynamic>? clasificacion, List<Map<String, dynamic>> resultados = const [], String titulo = 'Perfil lipídico'}) => {
      'id': 'e1',
      'pacienteId': 'p1',
      'titulo': titulo,
      'tipoMime': 'application/pdf',
      'nombreArchivo': 'resultado.pdf',
      'estadoExtraccion': resultados.isEmpty ? 'NO_RECONOCIDO' : 'EXTRAIDO',
      'validadoPorMedico': false,
      'cargadoEn': '2026-11-05T14:00:00.000Z',
      'resultados': resultados,
      if (clasificacion != null) 'clasificacion': clasificacion,
      'tituloAutomatico': true,
    };

const _categorias = [
  CategoriaCatalogo('Laboratorio clínico', ['Perfil lipídico', 'Hematología completa']),
  CategoriaCatalogo('Imagenología', ['Radiografía de tórax']),
  CategoriaCatalogo(categoriaOtro, []),
];

Future<List<EleccionClasificacion>> _montar(WidgetTester tester, ClasificacionExamen? inicial) async {
  final elecciones = <EleccionClasificacion>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: SelectorClasificacion(categorias: _categorias, inicial: inicial, alCambiar: elecciones.add))),
  ));
  return elecciones;
}

void main() {
  group('Datos', () {
    test('lee la sugerencia de la IA con su confianza', () {
      final e = ExamenMapper.examen(examenJson(clasificacion: {'categoria': 'Laboratorio clínico', 'tipo': 'Perfil lipídico', 'confianza': 0.92, 'origen': 'IA'}));
      expect(e.clasificacion!.sugeridaPorIa, isTrue);
      expect(e.clasificacion!.confianzaLegible, '92 %');
      expect(e.sinClasificar, isFalse);
      expect(e.tituloAutomatico, isTrue);
    });

    test('un examen sin clasificación queda por clasificar', () {
      expect(ExamenMapper.examen(examenJson()).sinClasificar, isTrue);
    });

    test('solo se envía la clasificación si cambió o no había', () {
      const guardada = ClasificacionExamen(categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', origen: 'IA', confianza: 0.9);
      expect(const EleccionClasificacion(categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico').cambiaRespectoDe(guardada), isFalse);
      expect(const EleccionClasificacion(categoria: 'Laboratorio clínico', tipo: 'Hematología completa').cambiaRespectoDe(guardada), isTrue);
      expect(const EleccionClasificacion(categoria: 'Imagenología', tipo: 'Radiografía de tórax').cambiaRespectoDe(null), isTrue);
      expect(const EleccionClasificacion(categoria: 'Otro').completa, isFalse);
    });
  });

  group('Mensaje al terminar la carga', () {
    test('con sugerencia y valores', () {
      final e = ExamenMapper.examen(examenJson(
        clasificacion: {'categoria': 'Laboratorio clínico', 'tipo': 'Perfil lipídico', 'confianza': 0.9, 'origen': 'IA'},
        resultados: [{'analito': 'Colesterol total', 'valor': '182'}],
      ));
      expect(mensajeTrasSubir(e), 'Parece un examen de «Perfil lipídico». Detectamos 1 valor. Revísalos antes de guardar.');
    });

    test('si la IA falló pide elegir la categoría y el tipo', () {
      expect(mensajeTrasSubir(ExamenMapper.examen(examenJson())), contains('Elige la categoría y el tipo'));
    });
  });

  group('SelectorClasificacion', () {
    testWidgets('muestra la sugerencia con su confianza ya seleccionada', (tester) async {
      await _montar(tester, const ClasificacionExamen(categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', origen: 'IA', confianza: 0.92));
      expect(find.text('Sugerido por la app · 92 %'), findsOneWidget);
      expect(find.text('Laboratorio clínico'), findsOneWidget);
      expect(find.text('Perfil lipídico'), findsOneWidget);
    });

    testWidgets('sin sugerencia avisa que hay que elegir', (tester) async {
      await _montar(tester, null);
      expect(find.textContaining('No pudimos reconocer el tipo de examen'), findsOneWidget);
    });

    testWidgets('el paciente corrige la sugerencia eligiendo otra categoría y tipo', (tester) async {
      final elecciones = await _montar(tester, const ClasificacionExamen(categoria: 'Laboratorio clínico', tipo: 'Perfil lipídico', origen: 'IA', confianza: 0.6));
      await tester.tap(find.byKey(const Key('categoria-examen')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imagenología').last);
      await tester.pumpAndSettle();
      expect(elecciones.last.categoria, 'Imagenología');
      expect(elecciones.last.completa, isFalse);
      await tester.tap(find.byKey(const ValueKey('tipo-examen-Imagenología')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Radiografía de tórax').last);
      await tester.pumpAndSettle();
      expect(elecciones.last.tipo, 'Radiografía de tórax');
      expect(elecciones.last.completa, isTrue);
    });

    testWidgets('con la categoría "Otro" se escribe el tipo', (tester) async {
      final elecciones = await _montar(tester, null);
      await tester.tap(find.byKey(const Key('categoria-examen')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(categoriaOtro).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tipo-examen-libre')), 'Prueba de embarazo');
      expect(elecciones.last.categoria, categoriaOtro);
      expect(elecciones.last.tipo, 'Prueba de embarazo');
    });
  });
}
