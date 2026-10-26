import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/expediente.dart';
import '../cubit/expediente_cubits.dart';

/// Médico: pacientes que le concedieron acceso a su expediente.
class MisPacientesPage extends StatelessWidget {
  const MisPacientesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MisPacientesCubit>()..cargar(),
      child: BlocBuilder<MisPacientesCubit, Recurso<List<PacienteAutorizado>>>(builder: (context, estado) {
        return SingleChildScrollView(
          child: ContenidoCentrado(
            maxAncho: 960,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Encabezado(
                antetitulo: 'Expedientes',
                titulo: 'Mis pacientes',
                descripcion: 'Solo aparecen los pacientes con un permiso vigente. Cada consulta queda registrada en la auditoría del paciente.',
              ),
              switch (estado) {
                RecursoError(:final mensaje) => VistaError(mensaje, reintentar: context.read<MisPacientesCubit>().cargar),
                RecursoListo(:final datos) when datos.isEmpty =>
                  const VistaVacia(icono: Icons.folder_off_outlined, titulo: 'Aún no tienes pacientes autorizados'),
                RecursoListo(:final datos) => Wrap(spacing: 14, runSpacing: 14, children: [
                    for (final p in datos)
                      SizedBox(
                        width: 440,
                        child: BwTarjeta(
                          onTap: () => context.push('/medico/pacientes/${p.pacienteId}'),
                          child: Row(children: [
                            AvatarIniciales(p.nombre, radio: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                Text('${p.edad} años · acceso hasta ${Formatos.fechaCorta(p.validoHasta)}',
                                    style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
                                const SizedBox(height: 6),
                                Wrap(spacing: 4, runSpacing: 4, children: [
                                  for (final c in p.categorias)
                                    ChipEstado(categoriasClinicas[c] ?? c, color: AppColors.primario, fondo: AppColors.superficieAzul2),
                                ]),
                              ]),
                            ),
                            const Icon(Icons.chevron_right),
                          ]),
                        ),
                      ),
                  ]),
                _ => const VistaCargando(),
              },
            ]),
          ),
        );
      }),
    );
  }
}
