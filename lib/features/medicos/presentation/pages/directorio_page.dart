import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/medico.dart';
import '../cubit/medicos_cubits.dart';
import '../widgets/tarjeta_medico.dart';

/// Paso 1 de 3 del agendamiento: "Selecciona a tu especialista".
class DirectorioPage extends StatelessWidget {
  const DirectorioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DirectorioCubit>()..iniciar(),
      child: const _Vista(),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DirectorioCubit>();
    final ancho = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IndicadorPasos(pasos: ['Especialista', 'Horario', 'Confirmación'], actual: 0),
          const SizedBox(height: 22),
          const Encabezado(antetitulo: 'Paso 1 de 3', titulo: 'Selecciona a tu especialista'),
          BlocBuilder<DirectorioCubit, Recurso<List<Medico>>>(
            builder: (context, estado) => BwTarjeta(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  decoration: AppTheme.campo('Buscar por médico o especialidad', icono: Icons.search),
                  onSubmitted: (v) {
                    cubit.texto = v.trim();
                    cubit.buscar();
                  },
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Text('Especialidad:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: cubit.especialidad == null,
                    onSelected: (_) => cubit.filtrar(limpiarEspecialidad: true),
                  ),
                  for (final e in cubit.especialidades)
                    ChoiceChip(label: Text(e), selected: cubit.especialidad == e, onSelected: (_) => cubit.filtrar(especialidad: e)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Text('Modalidad:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ChoiceChip(label: const Text('Todas'), selected: cubit.modalidad == null, onSelected: (_) => cubit.filtrar(limpiarModalidad: true)),
                  ChoiceChip(
                    avatar: const Icon(Icons.apartment, size: 16),
                    label: const Text('Presencial'),
                    selected: cubit.modalidad == 'PRESENCIAL',
                    onSelected: (_) => cubit.filtrar(modalidad: 'PRESENCIAL'),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.videocam_outlined, size: 16),
                    label: const Text('En línea / videollamada'),
                    selected: cubit.modalidad == 'VIRTUAL',
                    onSelected: (_) => cubit.filtrar(modalidad: 'VIRTUAL'),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: BlocBuilder<DirectorioCubit, Recurso<List<Medico>>>(builder: (context, estado) {
                return switch (estado) {
                  RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.buscar),
                  RecursoListo(:final datos) when datos.isEmpty => const VistaVacia(
                      icono: Icons.person_search_outlined,
                      titulo: 'No encontramos especialistas con esos filtros',
                      mensaje: 'Prueba con otra especialidad o modalidad.',
                    ),
                  RecursoListo(:final datos) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mostrando ${datos.length} especialistas verificados', style: const TextStyle(color: AppColors.pizarra)),
                      const SizedBox(height: 12),
                      for (final m in datos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TarjetaMedico(
                            medico: m,
                            alSeleccionar: () => context.push('/agendar/${m.id}'),
                            alVerPerfil: () => context.push('/medicos/${m.id}'),
                          ),
                        ),
                    ]),
                  _ => const VistaCargando(),
                };
              }),
            ),
            if (ancho >= 1100) ...[
              const SizedBox(width: 24),
              SizedBox(width: 320, child: _PanelLateral()),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _PanelLateral extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(24)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ORIENTACIÓN MÉDICA', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          SizedBox(height: 10),
          Text('¿Tienes dudas sobre qué especialista necesitas?', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          Text('Empieza por Medicina General: tu médico podrá referirte a un especialista de la red compartiendo tu expediente, siempre con tu aprobación.',
              style: TextStyle(color: Color(0xCCFFFFFF), height: 1.5, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 16),
      const BwTarjeta(
        child: Row(children: [
          Icon(Icons.shield_outlined, color: AppColors.primario),
          SizedBox(width: 12),
          Expanded(
            child: Text('Pago protegido: el cobro se retiene y se libera al médico 24 h después de tu consulta.',
                style: TextStyle(fontSize: 13, color: AppColors.pizarra, height: 1.4)),
          ),
        ]),
      ),
    ]);
  }
}
