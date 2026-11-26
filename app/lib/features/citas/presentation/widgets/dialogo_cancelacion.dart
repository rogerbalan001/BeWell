import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_textos.dart';
import '../../../../core/utils/formatos.dart';
import '../../domain/entities/cita.dart';

/// Cuánto se devuelve y cuánto se retiene si la cita se cancela ahora.
class DesgloseCancelacion {
  const DesgloseCancelacion({
    required this.pagado,
    required this.reembolso,
    required this.horasMinimasAviso,
    required this.nombrePolitica,
    required this.porMedico,
  });

  factory DesgloseCancelacion.de(Cita c, {required bool porMedico}) {
    final pagado = c.pago?.monto ?? c.monto;
    return DesgloseCancelacion(
      pagado: pagado,
      reembolso: porMedico ? pagado : (c.reembolsoSiCancelaAhora ?? pagado).clamp(0, pagado).toDouble(),
      horasMinimasAviso: c.politica.horasMinimasAviso,
      nombrePolitica: c.politica.nombre,
      porMedico: porMedico,
    );
  }

  final double pagado;
  final double reembolso;
  final int horasMinimasAviso;
  final String nombrePolitica;
  final bool porMedico;

  double get retenido => (pagado - reembolso).clamp(0, pagado).toDouble();
  int get porcentajeRetenido => pagado <= 0 ? 0 : (retenido / pagado * 100).round();
  bool get esTardia => retenido > 0;

  String get explicacion {
    if (porMedico) return 'Al cancelar como médico se devuelve el 100 % al paciente.';
    if (!esTardia) return 'Cancelas con al menos $horasMinimasAviso h de anticipación, así que se te devuelve el 100 %.';
    return 'Faltan menos de $horasMinimasAviso h para tu cita. Según la política ${nombrePolitica.toLowerCase()} del médico, '
        'se retiene el $porcentajeRetenido % para compensar el horario que apartó para ti, y se te devuelve el resto.';
  }
}

/// Diálogo único de cancelación: muestra el desglose, explica la retención y pide el motivo.
/// Devuelve el motivo escrito, o null si la persona decide volver.
Future<String?> pedirCancelacion(BuildContext context, Cita cita, {required bool porMedico}) {
  final d = DesgloseCancelacion.de(cita, porMedico: porMedico);
  return showDialog<String>(context: context, builder: (_) => _DialogoCancelacion(desglose: d, moneda: cita.moneda));
}

class _DialogoCancelacion extends StatefulWidget {
  const _DialogoCancelacion({required this.desglose, required this.moneda});
  final DesgloseCancelacion desglose;
  final String moneda;

  @override
  State<_DialogoCancelacion> createState() => _DialogoCancelacionState();
}

class _DialogoCancelacionState extends State<_DialogoCancelacion> {
  final _motivo = TextEditingController();
  bool _intento = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Widget _fila(String etiqueta, double monto, {Color? color, bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(etiqueta, style: AppTextos.secundario)),
          Text(
            Formatos.dinero(monto, widget.moneda),
            style: TextStyle(fontWeight: fuerte ? FontWeight.w700 : FontWeight.w600, color: color),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.desglose;
    final vacio = _motivo.text.trim().isEmpty;
    return AlertDialog(
      title: const Text('Cancelar cita'),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _fila('Monto pagado', d.pagado),
          _fila('Se te devuelve', d.reembolso, color: AppColors.verdeOscuro, fuerte: true),
          _fila(d.esTardia ? 'Se retiene (${d.porcentajeRetenido} %)' : 'Se retiene', d.retenido,
              color: d.esTardia ? AppColors.error : null),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: d.esTardia ? AppColors.ambarSuave : AppColors.superficieAzul2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(d.explicacion, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _motivo,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Motivo de la cancelación',
              hintText: 'Cuéntanos brevemente por qué cancelas',
              errorText: _intento && vacio ? 'Escribe el motivo para poder cancelar' : null,
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            if (_motivo.text.trim().isEmpty) {
              setState(() => _intento = true);
              return;
            }
            Navigator.pop(context, _motivo.text.trim());
          },
          child: const Text('Cancelar cita'),
        ),
      ],
    );
  }
}
