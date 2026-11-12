import 'package:bewell/core/utils/formatos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las iniciales se calculan con nombre y apellido', () {
    expect(Formatos.iniciales('Sofía Morales'), 'SM');
    expect(Formatos.iniciales('Mateo'), 'M');
  });
}
