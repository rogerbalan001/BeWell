import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/examen.dart';
import '../cubit/examenes_cubit.dart';
import 'resultados_widget.dart';

/// Exámenes del perfil activo: órdenes pendientes y resultados cargados.
class ExamenesPage extends StatelessWidget {
  const ExamenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final p = s.seleccionado;
        if (p == null) return const VistaCargando();
        return BlocProvider(key: ValueKey(p.id), create: (_) => sl<ExamenesCubit>()..cargar(p.id), child: _Vista(p.id));
      },
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista(this.pacienteId);
  final String pacienteId;

  Future<void> _subir(BuildContext context, {SolicitudExamen? solicitud}) async {
    final query = solicitud == null ? '' : '?solicitudId=${solicitud.id}&titulo=${Uri.encodeComponent(solicitud.examenes.join(', '))}';
    await context.push('/examenes/subir$query');
    if (context.mounted) context.read<ExamenesCubit>().cargar(pacienteId, silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExamenesCubit>();
    return BlocBuilder<ExamenesCubit, Recurso<DatosExamenes>>(builder: (context, estado) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Laboratorios y estudios',
              titulo: 'Mis exámenes',
              descripcion: 'Sube fotos o PDF de tus resultados (hasta 10 MB). Detectamos los valores para que no tengas que transcribirlos.',
              accion: FilledButton.icon(onPressed: () => _subir(context), icon: const Icon(Icons.upload_file), label: const Text('Subir examen')),
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => cubit.cargar(pacienteId)),
              RecursoListo(:final datos) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (datos.solicitudes.any((s) => s.pendiente)) ...[
                    const Text('Órdenes pendientes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 10),
                    for (final s in datos.solicitudes.where((s) => s.pendiente))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BwTarjeta(
                          color: AppColors.ambarSuave,
                          child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 10, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.examenes.join(' · '), style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('Indicada por ${s.medico?.nombreCompleto ?? 'tu médico'} · ${Formatos.fechaCorta(s.creadaEn)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.pizarra)),
                              if (s.indicaciones.isNotEmpty) Text('Indicaciones: ${s.indicaciones}', style: const TextStyle(fontSize: 13)),
                            ]),
                            FilledButton.icon(
                              onPressed: () => _subir(context, solicitud: s),
                              icon: const Icon(Icons.upload),
                              label: const Text('Subir resultados'),
                            ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Resultados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 10),
                  if (datos.examenes.isEmpty)
                    const VistaVacia(icono: Icons.biotech_outlined, titulo: 'Aún no has cargado exámenes')
                  else
                    for (final e in datos.examenes) _TarjetaExamen(e),
                ]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }
}

class _TarjetaExamen extends StatelessWidget {
  const _TarjetaExamen(this.e);
  final Examen e;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(e.esPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, color: AppColors.primario, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${e.nombreArchivo} · ${Formatos.fechaCorta(e.fechaExamen ?? e.cargadoEn)}', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
              ]),
            ),
            ChipEstado(
              e.estadoLegible,
              color: e.estadoExtraccion == 'EXTRAIDO' ? AppColors.ambar : (e.estadoExtraccion == 'CONFIRMADO' ? AppColors.verde : AppColors.pizarraClara),
            ),
          ]),
          if (e.resultados.isNotEmpty) ...[
            const SizedBox(height: 12),
            TablaResultados(resultados: e.resultados),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
              onPressed: () async {
                final error = await intentar(() async {
                  final url = await context.read<ExamenesCubit>().listar.urlArchivo(e.id);
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                });
                if (error != null && context.mounted) mostrarMensaje(context, error, error: true);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ver archivo original'),
            ),
            if (e.estadoExtraccion == 'EXTRAIDO')
              TextButton.icon(
                onPressed: () async {
                  final cubit = context.read<ExamenesCubit>();
                  await context.push('/examenes/${e.id}/revisar', extra: e);
                  cubit.cargar(e.pacienteId, silencioso: true);
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Revisar valores'),
              ),
          ]),
        ]),
      ),
    );
  }
}
