import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/recipes_usecases.dart';
import '../cubit/recipes_cubit.dart';
import 'recipe_widgets.dart';

/// Récipes del perfil activo (paciente) o récipes emitidos (médico).
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final esMedico = context.read<SesionCubit>().usuario?.esMedico ?? false;
    if (esMedico) {
      return BlocProvider(create: (_) => sl<RecipesCubit>()..emitidos(), child: const _Vista(esMedico: true));
    }
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final p = s.seleccionado;
        if (p == null) return const VistaCargando();
        return BlocProvider(key: ValueKey(p.id), create: (_) => sl<RecipesCubit>()..dePaciente(p.id), child: const _Vista(esMedico: false));
      },
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.esMedico});
  final bool esMedico;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipesCubit, Recurso<List<Recipe>>>(builder: (context, estado) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 900,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Récipes digitales',
              titulo: esMedico ? 'Récipes emitidos' : 'Mis récipes',
              descripcion: 'Firmados digitalmente (ECDSA P-256) y verificables por cualquier farmacia con su código o QR.',
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje),
              RecursoListo(:final datos) when datos.isEmpty => const VistaVacia(icono: Icons.receipt_long_outlined, titulo: 'No hay récipes todavía'),
              RecursoListo(:final datos) => Column(children: [for (final r in datos) _TarjetaRecipe(r, esMedico: esMedico)]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }
}

class _TarjetaRecipe extends StatelessWidget {
  const _TarjetaRecipe(this.r, {required this.esMedico});
  final Recipe r;
  final bool esMedico;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        onTap: () => mostrarRecipeConQr(context, r),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.receipt_long, color: AppColors.primario),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.codigo, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              Text(esMedico ? 'Paciente: ${r.pacienteNombre}' : '${r.medicoNombre} · ${r.especialidad}', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
              Text('${r.items.map((i) => i.medicamento).join(', ')} · ${Formatos.fechaCorta(r.emitidoEn)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ]),
          ),
          ChipEstado(r.vigente ? 'Vigente' : (r.estado == 'ANULADO' ? 'Anulado' : 'Vencido'), color: r.vigente ? AppColors.verde : AppColors.error),
          if (esMedico && r.estado == 'VIGENTE')
            IconButton(
              tooltip: 'Anular',
              icon: const Icon(Icons.block, color: AppColors.error),
              onPressed: () async {
                final motivo = await pedirTexto(context, titulo: 'Anular récipe ${r.codigo}', etiqueta: 'Motivo de la anulación', accion: 'Anular');
                if (motivo == null || !context.mounted) return;
                final cubit = context.read<RecipesCubit>();
                final error = await intentar(() => sl<EmitirRecipe>().anular(r.id, motivo));
                if (!context.mounted) return;
                mostrarMensaje(context, error ?? 'Récipe anulado: las farmacias lo verán como inválido', error: error != null);
                cubit.emitidos(silencioso: true);
              },
            ),
        ]),
      ),
    );
  }
}
