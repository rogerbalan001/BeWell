import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/presentation/cubit/medicos_cubits.dart';
import '../../../medicos/presentation/pages/credenciales_page.dart';

/// HU administrador: validar título, colegiatura y cédula de cada médico.
class VerificacionesPage extends StatelessWidget {
  const VerificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<VerificacionesCubit>()..cargar(),
      child: BlocBuilder<VerificacionesCubit, Recurso<List<Medico>>>(builder: (context, estado) {
        final cubit = context.read<VerificacionesCubit>();
        return SingleChildScrollView(
          child: ContenidoCentrado(
            maxAncho: 1000,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Encabezado(
                antetitulo: 'Administración',
                titulo: 'Verificación de médicos',
                descripcion: 'Revisa cada documento y aprueba o rechaza indicando el motivo. Solo los médicos aprobados aparecen en el directorio.',
                accion: OutlinedButton.icon(onPressed: cubit.cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
              ),
              switch (estado) {
                RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.cargar),
                RecursoListo(:final datos) when datos.isEmpty =>
                  const VistaVacia(icono: Icons.task_alt, titulo: 'No hay credenciales pendientes', mensaje: 'Todo al día.'),
                RecursoListo(:final datos) => Column(children: [for (final m in datos) _TarjetaSolicitud(m)]),
                _ => const VistaCargando(),
              },
            ]),
          ),
        );
      }),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud(this.medico);
  final Medico medico;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VerificacionesCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SeccionTarjeta(
        titulo: medico.nombreCompleto,
        subtitulo: '${medico.especialidad} · Estado global: ${textoEstadoVerificacion(medico.estadoVerificacion)}',
        icono: Icons.person_outline,
        child: Column(children: [
          for (final c in medico.credenciales)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(16)),
              child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 8, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.nombreTipo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('N.º ${c.numero}${c.enviadaEn != null ? ' · enviada ${Formatos.fechaCorta(c.enviadaEn!)}' : ''}',
                      style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
                ]),
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  ChipEstado(textoEstadoVerificacion(c.estado), color: colorEstadoVerificacion(c.estado)),
                  IconButton(
                    tooltip: 'Ver documento',
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () async {
                      final error = await intentar(() async {
                        final url = await cubit.revisar.urlDocumento(medico.id, c.id);
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      });
                      if (error != null && context.mounted) mostrarMensaje(context, error, error: true);
                    },
                  ),
                  if (c.estado == 'PENDIENTE') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      onPressed: () async {
                        final motivo = await pedirTexto(context, titulo: 'Rechazar ${c.nombreTipo.toLowerCase()}', etiqueta: 'Motivo del rechazo', accion: 'Rechazar');
                        if (motivo == null) return;
                        final error = await intentar(() => cubit.revisar.rechazar(medico.id, c.id, motivo));
                        if (!context.mounted) return;
                        mostrarMensaje(context, error ?? 'Credencial rechazada; se notificó al médico', error: error != null);
                        cubit.cargar();
                      },
                      child: const Text('Rechazar'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final error = await intentar(() => cubit.revisar.aprobar(medico.id, c.id));
                        if (!context.mounted) return;
                        mostrarMensaje(context, error ?? 'Credencial aprobada', error: error != null);
                        cubit.cargar();
                      },
                      child: const Text('Aprobar'),
                    ),
                  ],
                ]),
              ]),
            ),
        ]),
      ),
    );
  }
}
