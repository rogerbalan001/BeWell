import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../domain/entities/cita.dart';

/// Abre la página de PayPal donde el paciente aprueba el pago.
/// En la web se abre en la misma pestaña (PayPal vuelve a Bewell al terminar);
/// en el teléfono se abre en el navegador o en la app de PayPal.
Future<bool> abrirPayPal(String url) {
  final uri = Uri.parse(url);
  return kIsWeb ? launchUrl(uri, webOnlyWindowName: '_self') : launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Mensaje al volver de PayPal (`?pago=` en la URL de la cita).
String? mensajeRetornoPago(String? resultado) => switch (resultado) {
      'ok' => '¡Pago recibido! Tu cita está confirmada.',
      'pendiente' => 'Aún no vemos el pago aprobado en PayPal. Si ya pagaste, toca "Ya pagué, verificar".',
      'cancelado' => 'Cancelaste el pago en PayPal. Tu horario sigue apartado unos minutos: puedes intentarlo de nuevo.',
      'rechazado' => 'PayPal rechazó el pago y la cita no se confirmó.',
      'error' => 'No pudimos confirmar el pago con PayPal. Revisa el estado de tu cita.',
      _ => null,
    };

/// Tarjeta "Completa tu pago": aparece mientras la reserva espera el pago en PayPal.
class TarjetaPagoPendiente extends StatelessWidget {
  const TarjetaPagoPendiente({
    super.key,
    required this.cita,
    required this.vistaMedico,
    required this.ocupado,
    required this.onPagar,
    required this.onVerificar,
    required this.onCancelar,
  });

  final Cita cita;
  final bool vistaMedico;
  final bool ocupado;
  final VoidCallback onPagar;
  final VoidCallback onVerificar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    if (vistaMedico) {
      return _caja(const Text(
        'El paciente todavía no completa el pago en PayPal. Si no paga en 30 minutos, el horario se libera.',
        style: TextStyle(fontSize: 13, color: AppColors.ambar, height: 1.4),
      ));
    }
    return _caja(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [
        Icon(Icons.timer_outlined, color: AppColors.ambar, size: 20),
        SizedBox(width: 8),
        Expanded(child: Text('Completa tu pago para confirmar la cita', style: TextStyle(fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 6),
      Text(
        'Apartamos tu horario por 30 minutos. Paga ${Formatos.dinero(cita.monto, cita.moneda)} con PayPal; '
        'el dinero queda retenido y solo se le entrega al médico 24 h después de tu consulta.',
        style: const TextStyle(fontSize: 12.5, color: AppColors.pizarra, height: 1.4),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: ocupado || cita.urlPago == null ? null : onPagar,
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Pagar con PayPal'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: ocupado ? null : onVerificar,
        icon: const Icon(Icons.refresh),
        label: const Text('Ya pagué, verificar'),
      ),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: ocupado ? null : onCancelar,
        child: const Text('Cancelar reserva'),
      ),
    ]));
  }

  Widget _caja(Widget hijo) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.ambarSuave, borderRadius: BorderRadius.circular(14)),
        child: hijo,
      );
}
