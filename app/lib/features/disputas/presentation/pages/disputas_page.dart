import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/disputa.dart';
import '../cubit/disputas_cubit.dart';

/// Administrador: revisa los pagos retenidos por un reporte del paciente y decide
/// si el dinero se libera al médico o se reembolsa al paciente.
class DisputasPage extends StatelessWidget {
  const DisputasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<DisputasCubit>()..cargar(), child: const DisputasVista());
  }
}

/// Contenido de la pantalla, separado para poder probarlo con un cubit de prueba.
class DisputasVista extends StatelessWidget {
  const DisputasVista({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisputasCubit, Recurso<List<Disputa>>>(builder: (context, estado) {
      final cubit = context.read<DisputasCubit>();
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 1000,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Administración',
              titulo: 'Disputas de pago',
              descripcion: 'Pagos retenidos porque el paciente reportó un problema con la consulta. '
                  'Lee el motivo y decide: liberar el dinero al médico o reembolsarlo al paciente. Ambos reciben un aviso.',
              accion: OutlinedButton.icon(onPressed: cubit.cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.cargar),
              RecursoListo(:final datos) when datos.isEmpty => const VistaVacia(
                  icono: Icons.verified_outlined,
                  titulo: 'No hay disputas abiertas',
                  mensaje: 'Cuando un paciente reporte un problema con una consulta, aparecerá aquí.',
                ),
              RecursoListo(:final datos) => Column(children: [for (final d in datos) TarjetaDisputa(d)]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }
}

/// Una disputa con su motivo y las dos acciones posibles.
class TarjetaDisputa extends StatefulWidget {
  const TarjetaDisputa(this.disputa, {super.key});
  final Disputa disputa;

  @override
  State<TarjetaDisputa> createState() => _TarjetaDisputaState();
}

class _TarjetaDisputaState extends State<TarjetaDisputa> {
  bool _ocupado = false;

  Disputa get d => widget.disputa;

  Future<void> _resolver(AccionDisputa accion) async {
    final liberar = accion == AccionDisputa.liberar;
    final monto = Formatos.dinero(d.monto, d.moneda);
    final ok = await confirmar(
      context,
      titulo: liberar ? 'Liberar el pago al médico' : 'Reembolsar al paciente',
      mensaje: liberar
          ? 'Se entregarán $monto a ${d.medicoNombre}. Esta decisión no se puede deshacer.'
          : 'Se devolverán $monto a ${d.pacienteNombre}. Esta decisión no se puede deshacer.',
      accion: liberar ? 'Liberar' : 'Reembolsar',
      peligro: !liberar,
    );
    if (!ok || !mounted) return;
    final nota = await pedirTexto(
      context,
      titulo: 'Nota para el paciente y el médico',
      etiqueta: 'Explica brevemente la decisión (opcional)',
      accion: 'Confirmar',
      obligatorio: false,
    );
    if (nota == null || !mounted) return;
    setState(() => _ocupado = true);
    final error = await context.read<DisputasCubit>().resolver(d, accion, nota: nota);
    if (!mounted) return;
    setState(() => _ocupado = false);
    mostrarMensaje(context, error ?? (liberar ? 'Pago liberado al médico' : 'Reembolso enviado al paciente'), error: error != null);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SeccionTarjeta(
        titulo: '${d.pacienteNombre} · ${d.medicoNombre}',
        subtitulo: d.abiertaEn == null ? 'Reporte abierto' : 'Reportado el ${Formatos.fechaHora(d.abiertaEn!)}',
        icono: Icons.report_problem_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FilaDato('Monto retenido', Formatos.dinero(d.monto, d.moneda), destacado: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.ambarSuave, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Motivo del paciente', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ambar)),
              const SizedBox(height: 4),
              Text(d.motivo.isEmpty ? 'Sin motivo indicado' : d.motivo, style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.end, children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _ocupado ? null : () => _resolver(AccionDisputa.reembolsar),
              icon: const Icon(Icons.undo),
              label: const Text('Reembolsar al paciente'),
            ),
            FilledButton.icon(
              onPressed: _ocupado ? null : () => _resolver(AccionDisputa.liberar),
              icon: _ocupado
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Liberar al médico'),
            ),
          ]),
        ]),
      ),
    );
  }
}
