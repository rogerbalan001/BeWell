import 'package:bewell/features/citas/data/datasources/citas_remote_data_source.dart';
import 'package:bewell/features/citas/domain/entities/cita.dart';
import 'package:bewell/features/citas/presentation/widgets/dialogo_cancelacion.dart';
import 'package:flutter_test/flutter_test.dart';

Cita cita({required double reembolso}) {
  final inicio = DateTime.now().add(const Duration(hours: 10));
  final c = CitaMapper.desdeJson({
    'id': 'c1',
    'codigo': 'BW-00002',
    'estado': 'CONFIRMADA',
    'inicio': inicio.toUtc().toIso8601String(),
    'fin': inicio.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
    'modalidad': 'VIRTUAL',
    'motivo': 'Control',
    'monto': 50,
    'moneda': 'USD',
    'paciente': {'id': 'p1', 'nombreCompleto': 'Sofía Morales'},
    'medico': {'id': 'm1', 'nombreCompleto': 'Dra. Soto', 'especialidad': 'Endocrinología'},
    'politicaCancelacion': {'tipo': 'MODERADA', 'horasMinimasAviso': 24, 'porcentajePenalizacion': 0.5, 'descripcion': 'x'},
    'reembolsoSiCancelaAhora': reembolso,
  });
  return c;
}

void main() {
  test('cancelar tarde explica el monto y el porcentaje que se retiene', () {
    final d = DesgloseCancelacion.de(cita(reembolso: 25), porMedico: false);
    expect(d.pagado, 50);
    expect(d.reembolso, 25);
    expect(d.retenido, 25);
    expect(d.porcentajeRetenido, 50);
    expect(d.esTardia, isTrue);
    expect(d.explicacion, contains('50 %'));
    expect(d.explicacion, contains('24 h'));
  });

  test('cancelar a tiempo devuelve el 100 %', () {
    final d = DesgloseCancelacion.de(cita(reembolso: 50), porMedico: false);
    expect(d.retenido, 0);
    expect(d.esTardia, isFalse);
    expect(d.explicacion, contains('100 %'));
  });

  test('si cancela el médico, el paciente recibe todo', () {
    final d = DesgloseCancelacion.de(cita(reembolso: 25), porMedico: true);
    expect(d.reembolso, 50);
    expect(d.porcentajeRetenido, 0);
  });
}
