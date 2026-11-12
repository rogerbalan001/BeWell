import 'package:bewell/features/disputas/data/datasources/disputas_remote_data_source.dart';
import 'package:bewell/features/disputas/domain/entities/disputa.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee una disputa de GET /pagos/disputas', () {
    final d = DisputaMapper.desdeJson({
      'id': 'p1',
      'citaId': 'c1',
      'monto': 50,
      'moneda': 'USD',
      'estado': 'EN_DISPUTA',
      'motivoDisputa': 'El médico no se conectó',
      'pacienteNombre': 'Sofía Morales',
      'medicoNombre': 'Dr. Ruiz',
      'abiertaEn': '2026-11-05T14:00:00.000Z',
    });
    expect(d.abierta, isTrue);
    expect(d.motivo, 'El médico no se conectó');
    expect(d.monto, 50);
    expect(d.abiertaEn, isNotNull);
  });

  test('una disputa resuelta ya no está abierta', () {
    final d = DisputaMapper.desdeJson({'id': 'p1', 'citaId': 'c1', 'monto': 50, 'estado': 'REEMBOLSADO'});
    expect(d.abierta, isFalse);
    expect(d.pacienteNombre, 'Paciente');
  });

  test('las acciones usan los códigos de la API', () {
    expect(AccionDisputa.liberar.codigo, 'LIBERAR');
    expect(AccionDisputa.reembolsar.codigo, 'REEMBOLSAR');
  });
}
