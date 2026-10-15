import 'package:bewell/core/utils/formatos.dart';
import 'package:bewell/features/citas/domain/entities/cita.dart';
import 'package:bewell/features/medicos/domain/entities/medico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las iniciales se calculan con nombre y apellido', () {
    expect(Formatos.iniciales('Sofía Morales'), 'SM');
    expect(Formatos.iniciales('Mateo'), 'M');
  });

  test('una cita atendida permite reportar problema solo mientras el pago sigue retenido', () {
    Cita cita(DateTime libera, String estadoPago) => Cita(
          id: '1',
          codigo: 'BW-1',
          estado: 'ATENDIDA',
          inicio: DateTime.now().subtract(const Duration(hours: 2)),
          fin: DateTime.now().subtract(const Duration(hours: 1)),
          modalidad: 'VIRTUAL',
          motivo: '',
          monto: 45,
          moneda: 'USD',
          pacienteId: 'p',
          pacienteNombre: 'Sofía',
          medicoId: 'm',
          medicoNombre: 'Mateo Ruiz',
          especialidad: 'Medicina General',
          politica: const PoliticaCancelacion(tipo: 'FLEXIBLE', horasMinimasAviso: 2, porcentajePenalizacion: 0.5, descripcion: ''),
          pago: PagoResumen(estado: estadoPago, monto: 45, montoReembolsado: 0, liberarDespuesDe: libera),
        );
    expect(cita(DateTime.now().add(const Duration(hours: 20)), 'RETENIDO').puedeReportarProblema, isTrue);
    expect(cita(DateTime.now().subtract(const Duration(hours: 1)), 'RETENIDO').puedeReportarProblema, isFalse);
    expect(cita(DateTime.now().add(const Duration(hours: 20)), 'LIBERADO').puedeReportarProblema, isFalse);
  });
}
