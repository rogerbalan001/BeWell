import 'package:bewell/features/citas/data/datasources/citas_remote_data_source.dart';
import 'package:bewell/features/citas/presentation/widgets/pago_paypal.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> citaJson({required String estado, Map<String, dynamic>? pago}) => {
      'id': 'c1',
      'codigo': 'BW-00001',
      'estado': estado,
      'inicio': '2026-11-02T13:00:00.000Z',
      'fin': '2026-11-02T13:30:00.000Z',
      'modalidad': 'VIRTUAL',
      'motivo': 'Control',
      'monto': 45,
      'moneda': 'USD',
      'paciente': {'id': 'p1', 'nombreCompleto': 'Sofía Morales'},
      'medico': {'id': 'm1', 'nombreCompleto': 'Dra. Soto', 'especialidad': 'Endocrinología'},
      'politicaCancelacion': {'tipo': 'MODERADA', 'horasMinimasAviso': 24, 'porcentajePenalizacion': 50, 'descripcion': 'x'},
      if (pago != null) 'pago': pago,
    };

void main() {
  test('una reserva pendiente de PayPal trae la URL para pagar', () {
    final cita = CitaMapper.desdeJson(citaJson(estado: 'PENDIENTE_PAGO', pago: {
      'estado': 'PENDIENTE_APROBACION',
      'proveedor': 'PAYPAL',
      'monto': 45,
      'montoReembolsado': 0,
      'urlAprobacion': 'https://www.sandbox.paypal.com/checkoutnow?token=ORD-1',
    }));
    expect(cita.esperandoPago, isTrue);
    expect(cita.urlPago, 'https://www.sandbox.paypal.com/checkoutnow?token=ORD-1');
    expect(cita.pago!.esPayPal, isTrue);
    expect(cita.pago!.descripcion, 'Esperando el pago en PayPal');
    expect(cita.estadoLegible, 'Pendiente de pago');
  });

  test('una cita ya pagada con PayPal no ofrece volver a pagar', () {
    final cita = CitaMapper.desdeJson(citaJson(estado: 'CONFIRMADA', pago: {
      'estado': 'RETENIDO',
      'proveedor': 'PAYPAL',
      'monto': 45,
      'montoReembolsado': 0,
    }));
    expect(cita.esperandoPago, isFalse);
    expect(cita.urlPago, isNull);
    expect(cita.pago!.descripcion, 'Pago retenido (protegido)');
  });

  test('los pagos de demostración (sin proveedor) siguen funcionando', () {
    final cita = CitaMapper.desdeJson(citaJson(estado: 'CONFIRMADA', pago: {'estado': 'RETENIDO', 'monto': 45, 'montoReembolsado': 0}));
    expect(cita.pago!.esPayPal, isFalse);
    expect(cita.esperandoPago, isFalse);
  });

  test('el mensaje al volver de PayPal depende del resultado', () {
    expect(mensajeRetornoPago('ok'), contains('confirmada'));
    expect(mensajeRetornoPago('cancelado'), contains('Cancelaste'));
    expect(mensajeRetornoPago('rechazado'), contains('rechazó'));
    expect(mensajeRetornoPago(null), isNull);
  });
}
