import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../domain/entities/cita.dart';
import '../cubit/citas_cubits.dart';
import '../widgets/tarjeta_cita.dart';

/// "Mis citas" del paciente (todos sus perfiles) o agenda del médico.
class MisCitasPage extends StatelessWidget {
  const MisCitasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<MisCitasCubit>()..cargar(), child: const _Vista());
  }
}

class _Vista extends StatefulWidget {
  const _Vista();
  @override
  State<_Vista> createState() => _VistaState();
}

class _VistaState extends State<_Vista> {
  int _pestana = 0;

  List<Cita> _filtrar(List<Cita> citas) {
    final ahora = DateTime.now();
    return switch (_pestana) {
      0 => citas.where((c) => c.confirmada && c.fin.isAfter(ahora.subtract(const Duration(hours: 2)))).toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio)),
      1 => citas.where((c) => c.pendienteAceptacion).toList(),
      _ => citas.where((c) => !(c.confirmada && c.fin.isAfter(ahora.subtract(const Duration(hours: 2)))) && !c.pendienteAceptacion).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final esMedico = context.read<SesionCubit>().usuario?.esMedico ?? false;
    final cubit = context.read<MisCitasCubit>();
    return BlocBuilder<MisCitasCubit, Recurso<List<Cita>>>(builder: (context, estado) {
      return RefreshIndicator(
        onRefresh: () => cubit.cargar(silencioso: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ContenidoCentrado(
            maxAncho: 900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Encabezado(
                antetitulo: esMedico ? 'Mi consulta' : 'Mis citas',
                titulo: esMedico ? 'Agenda de pacientes' : 'Citas médicas',
                descripcion: esMedico
                    ? 'Marca las consultas como atendidas para registrar la nota clínica y liberar el pago en 24 h.'
                    : 'Las citas de todos tus perfiles familiares.',
                accion: esMedico
                    ? OutlinedButton.icon(onPressed: () => cubit.cargar(), icon: const Icon(Icons.refresh), label: const Text('Actualizar'))
                    : FilledButton.icon(onPressed: () => context.push('/directorio'), icon: const Icon(Icons.add), label: const Text('Reservar cita')),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Próximas'), icon: Icon(Icons.event_available)),
                  ButtonSegment(value: 1, label: Text('Por responder'), icon: Icon(Icons.pending_actions)),
                  ButtonSegment(value: 2, label: Text('Historial'), icon: Icon(Icons.history)),
                ],
                selected: {_pestana},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _pestana = s.first),
              ),
              const SizedBox(height: 16),
              switch (estado) {
                RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.cargar),
                RecursoListo(:final datos) => _Lista(_filtrar(datos), esMedico),
                _ => const VistaCargando(),
              },
            ]),
          ),
        ),
      );
    });
  }
}

class _Lista extends StatelessWidget {
  const _Lista(this.citas, this.esMedico);
  final List<Cita> citas;
  final bool esMedico;

  @override
  Widget build(BuildContext context) {
    if (citas.isEmpty) return const VistaVacia(icono: Icons.event_note_outlined, titulo: 'No hay citas en esta sección');
    return Column(children: [
      for (final c in citas)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TarjetaCita(
            cita: c,
            vistaMedico: esMedico,
            onTap: () async {
              await context.push('/citas/${c.id}');
              if (context.mounted) context.read<MisCitasCubit>().cargar(silencioso: true);
            },
          ),
        ),
    ]);
  }
}
