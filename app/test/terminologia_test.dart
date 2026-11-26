import 'package:bewell/core/clinico/terminologia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el buscador CIE-10 encuentra por código y por nombre sin tildes', () {
    expect(buscarCie10('I10').first.etiqueta, 'I10 Hipertensión esencial (primaria)');
    expect(buscarCie10('hipertension').map((c) => c.codigo), contains('I10'));
    expect(buscarCie10('diabetes tipo 2').map((c) => c.codigo), contains('E11.9'));
    expect(buscarCie10(''), isEmpty);
  });

  test('un diagnóstico sin código CIE-10 no es válido', () {
    expect(tieneCodigoCie10('J06.9 Infección aguda de las vías respiratorias superiores, no especificada'), isTrue);
    expect(tieneCodigoCie10('I10 Hipertensión esencial (primaria)'), isTrue);
    expect(tieneCodigoCie10('fiebre alta'), isFalse);
  });

  test('la dosis lleva cantidad y unidad estandarizada', () {
    expect(componerDosis('500', 'mg'), '500 mg');
    expect(componerDosis('1', 'tableta(s)'), '1 tableta');
    expect(componerDosis('2', 'cápsula(s)'), '2 cápsulas');
    expect(componerDosis('2', 'aplicación(es)'), '2 aplicaciones');
    for (final d in ['500 mg', '2.5 ml', '10 UI', '1 tableta', '2 cápsulas', '2 aplicaciones']) {
      expect(dosisValida(d), isTrue, reason: d);
    }
    expect(dosisValida('una pastilla'), isFalse);
    expect(dosisValida('500'), isFalse);
  });

  test('todas las unidades del formulario producen una dosis válida', () {
    for (final u in unidadesDosis) {
      expect(dosisValida(componerDosis('1', u)), isTrue, reason: u);
      expect(dosisValida(componerDosis('2', u)), isTrue, reason: u);
    }
  });

  test('la nota de evolución sigue el formato SOAP', () {
    final nota = componerNotaSoap(subjetivo: 'Cefalea', objetivo: 'PA 120/80', analisis: 'Cefalea tensional', plan: 'Paracetamol');
    expect(nota.split('\n').map((l) => l.substring(0, 1)), ['S', 'O', 'A', 'P']);
  });

  test('marca los valores fuera del rango de referencia', () {
    expect(posicionEnRango('13.5', '12.0 - 16.0'), 0);
    expect(posicionEnRango('18', '12-16'), 1);
    expect(posicionEnRango('10', '12–16'), -1);
    expect(posicionEnRango('250', '< 200'), 1);
    expect(posicionEnRango('150', '<200'), 0);
    expect(posicionEnRango('35', '> 40'), -1);
    expect(posicionEnRango('positivo', '< 200'), isNull);
  });
}
