import 'package:bewell/features/citas/data/datasources/citas_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> citaJson(String estado, DateTime inicio) => {
      'id': 'c-${inicio.millisecondsSinceEpoch}',
      'codigo': 'BW-00001',
      'estado': estado,
      'inicio': inicio.toUtc().toIso8601String(),
      'fin': inicio.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
      'modalidad': 'PRESENCIAL',
      'motivo': 'Control',
      'monto': 50,
      'moneda': 'USD',
      'paciente': {'id': 'p1', 'nombreCompleto': 'Sofía Morales'},
      'medico': {'id': 'm1', 'nombreCompleto': 'Dra. Soto', 'especialidad': 'Endocrinología'},
      'politicaCancelacion': {'tipo': 'MODERADA', 'horasMinimasAviso': 24, 'porcentajePenalizacion': 0.5, 'descripcion': 'x'},
    };

void main() {
  final ahora = DateTime.now();

  test('una cita confirmada que ya pasó dice "Por registrar por el médico", no "Confirmada"', () {
    final cita = CitaMapper.desdeJson(citaJson('CONFIRMADA', ahora.subtract(const Duration(days: 2))));
    expect(cita.porRegistrar, isTrue);
    expect(cita.estadoLegible, 'Por registrar por el médico');
  });

  test('una cita confirmada futura sigue como "Confirmada"', () {
    final cita = CitaMapper.desdeJson(citaJson('CONFIRMADA', ahora.add(const Duration(days: 2))));
    expect(cita.porRegistrar, isFalse);
    expect(cita.estadoLegible, 'Confirmada');
  });

  test('el historial muestra el estado que registró el médico', () {
    final atendida = CitaMapper.desdeJson(citaJson('ATENDIDA', ahora.subtract(const Duration(days: 3))));
    final ausente = CitaMapper.desdeJson(citaJson('NO_ASISTIO', ahora.subtract(const Duration(days: 3))));
    expect(atendida.estadoLegible, 'Atendida');
    expect(ausente.estadoLegible, 'No asistió');
  });
}
