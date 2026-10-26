import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/cita.dart';
import '../../domain/usecases/citas_usecases.dart';
import '../cubit/citas_cubits.dart';

/// Paso 3 de 3: "¡Tu cita está casi lista!". Al confirmar se retiene el pago.
class ConfirmacionCitaPage extends StatefulWidget {
  const ConfirmacionCitaPage({super.key, required this.borrador});
  final BorradorCita? borrador;

  @override
  State<ConfirmacionCitaPage> createState() => _ConfirmacionCitaPageState();
}

class _ConfirmacionCitaPageState extends State<ConfirmacionCitaPage> {
  String _metodo = 'TARJETA';
  bool _enviando = false;

  Future<void> _confirmar(String pacienteId) async {
    final b = widget.borrador!;
    setState(() => _enviando = true);
    try {
      final cita = await sl<AgendarCita>()(SolicitudCita(
        medicoId: b.medico.id,
        pacienteId: pacienteId,
        inicio: b.franja.inicio,
        modalidad: b.modalidad,
        motivo: b.motivo,
      ));
      if (!mounted) return;
      if (cita.confirmada) {
        mostrarMensaje(context, '¡Cita confirmada! Código ${cita.codigo}');
      } else {
        mostrarMensaje(context, 'La pasarela rechazó el pago; la cita no se confirmó.', error: true);
      }
      context.go('/citas/${cita.id}');
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarMensaje(context, f.mensaje, error: true);
      if (f.codigoHttp == 409) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borrador;
    if (b == null) {
      return VistaVacia(
        icono: Icons.event_busy,
        titulo: 'No hay una reserva en curso',
        accion: FilledButton(onPressed: () => context.go('/directorio'), child: const Text('Ir al directorio')),
      );
    }
    final m = b.medico;
    final ancho = MediaQuery.sizeOf(context).width;

    final detalle = BwTarjeta(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarIniciales(m.nombreCompleto, radio: 30, verificado: m.verificado),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(m.especialidad, style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w600)),
            ]),
          ),
          const ChipEstado('Cupo disponible', icono: Icons.verified),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _bloque(Icons.calendar_month, 'FECHA Y HORA', '${Formatos.fechaLarga(b.franja.inicio)}\n${Formatos.hora(b.franja.inicio)}'),
          _bloque(b.modalidad == 'VIRTUAL' ? Icons.videocam : Icons.apartment, 'MODALIDAD',
              b.modalidad == 'VIRTUAL' ? 'Consulta en línea\nVideollamada cifrada' : 'Presencial\n${m.direccion ?? ''}'),
        ]),
        const SizedBox(height: 18),
        const Text('Datos del paciente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        BlocBuilder<PerfilActivoCubit, PerfilesState>(builder: (context, s) {
          final p = s.seleccionado;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FilaDato('Paciente', p == null ? '—' : '${p.nombreCompleto} (${p.etiqueta})'),
            FilaDato('Motivo de consulta', b.motivo.isEmpty ? 'No indicado' : b.motivo),
          ]);
        }),
      ]),
    );

    final pago = BwTarjeta(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Desglose de cita', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        FilaDato('Honorarios médicos', Formatos.dinero(m.tarifa, m.moneda)),
        const FilaDato('Plataforma y gestión Bewell', 'Gratis'),
        const FilaDato('Récipe digital firmado', 'Incluido'),
        const Divider(height: 22),
        FilaDato('Importe total', Formatos.dinero(m.tarifa, m.moneda), destacado: true),
        const SizedBox(height: 14),
        const Text('MÉTODO DE PAGO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.pizarra)),
        const SizedBox(height: 8),
        for (final (valor, icono, titulo, texto) in const [
          ('TARJETA', Icons.credit_card, 'Tarjeta de débito o crédito', 'Datos tokenizados por la pasarela'),
          ('PAGO_MOVIL', Icons.phone_android, 'Pago móvil', 'Confirmación inmediata'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BwTarjeta(
              padding: const EdgeInsets.all(12),
              color: _metodo == valor ? AppColors.superficieAzul2 : AppColors.superficieAzul,
              borde: _metodo == valor ? AppColors.primario : Colors.transparent,
              onTap: () => setState(() => _metodo = valor),
              child: Row(children: [
                Icon(icono, color: AppColors.primario),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.pizarra)),
                  ]),
                ),
                if (_metodo == valor) const Icon(Icons.check_circle, color: AppColors.primario),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.verdeSuave, borderRadius: BorderRadius.circular(14)),
          child: Text(
            'El cobro se retiene y se libera al médico 24 h después de tu consulta. ${m.politica.descripcion}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.verdeOscuro, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<PerfilActivoCubit, PerfilesState>(
          builder: (context, s) => FilledButton.icon(
            onPressed: _enviando || s.seleccionado == null ? null : () => _confirmar(s.seleccionado!.id),
            icon: _enviando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar y agendar cita'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.edit_calendar), label: const Text('Modificar horario')),
      ]),
    );

    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(children: [
          const IndicadorPasos(pasos: ['Especialista', 'Fecha y hora', 'Confirmación'], actual: 2),
          const SizedBox(height: 26),
          const ChipEstado('Paso final de reserva', color: AppColors.primario, icono: Icons.lock_outline),
          const SizedBox(height: 10),
          const Text('¡Tu cita está casi lista!', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 6),
          const Text('Revisa los datos y la modalidad antes de asegurar tu espacio con el especialista.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.pizarra)),
          const SizedBox(height: 24),
          if (ancho >= 980)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: detalle),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: pago),
            ])
          else ...[
            detalle,
            const SizedBox(height: 16),
            pago,
          ],
        ]),
      ),
    );
  }

  Widget _bloque(IconData icono, String titulo, String texto) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: AppColors.primario, radius: 18, child: Icon(icono, color: Colors.white, size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.pizarra)),
            const SizedBox(height: 4),
            Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
