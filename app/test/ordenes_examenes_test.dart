import 'package:bewell/features/examenes/domain/entities/examen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SolicitudExamen orden(String estado) => SolicitudExamen(
        id: '1',
        pacienteId: 'p',
        examenes: const ['Hematología completa'],
        indicaciones: '',
        estado: estado,
        creadaEn: DateTime(2026, 10, 20),
      );

  test('el estado de la orden se muestra en palabras del médico', () {
    expect(orden('PENDIENTE').estadoLegible, 'Pendiente');
    expect(orden('COMPLETADA').estadoLegible, 'Resultados cargados');
    expect(orden('ANULADA').estadoLegible, 'Anulada');
  });

  test('solo una orden pendiente se puede anular', () {
    expect(orden('PENDIENTE').pendiente, isTrue);
    expect(orden('COMPLETADA').pendiente, isFalse);
    expect(orden('ANULADA').anulada, isTrue);
  });
}
