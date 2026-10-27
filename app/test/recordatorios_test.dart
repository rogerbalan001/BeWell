import 'package:bewell/features/recordatorios/domain/entities/recordatorio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada tipo de recordatorio se activa o desactiva por separado', () {
    const p = PreferenciasRecordatorio(citas: true, medicamentos: true, examenes: true);
    final sinMedicamentos = p.copiarCon(medicamentos: false);
    expect(sinMedicamentos.permite(TipoRecordatorio.medicamentos), isFalse);
    expect(sinMedicamentos.permite(TipoRecordatorio.citas), isTrue);
    expect(sinMedicamentos.permite(TipoRecordatorio.examenes), isTrue);
  });

  test('el código que envía la API se traduce al tipo', () {
    expect(TipoRecordatorio.desdeCodigo('MEDICAMENTOS'), TipoRecordatorio.medicamentos);
    expect(TipoRecordatorio.desdeCodigo('EXAMENES'), TipoRecordatorio.examenes);
  });
}
