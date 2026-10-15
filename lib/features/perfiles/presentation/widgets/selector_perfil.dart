import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../cubit/perfil_activo_cubit.dart';

/// Selector del perfil familiar activo (titular o dependiente).
class SelectorPerfil extends StatelessWidget {
  const SelectorPerfil({super.key, this.compacto = false});
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(builder: (context, s) {
      final actual = s.seleccionado;
      if (actual == null) return const SizedBox.shrink();
      return PopupMenuButton<String>(
        tooltip: 'Cambiar de perfil',
        onSelected: (id) => context.read<PerfilActivoCubit>().seleccionar(id),
        itemBuilder: (_) => [
          for (final p in s.perfiles)
            PopupMenuItem(
              value: p.id,
              child: Row(children: [
                AvatarIniciales(p.nombreCompleto, radio: 14),
                const SizedBox(width: 10),
                Expanded(child: Text('${p.nombreCompleto} · ${p.etiqueta}')),
                if (p.id == actual.id) const Icon(Icons.check, size: 18, color: AppColors.primario),
              ]),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AvatarIniciales(actual.nombreCompleto, radio: 13),
            const SizedBox(width: 8),
            if (!compacto)
              Text('${actual.nombres} · ${actual.etiqueta}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Icon(Icons.expand_more, size: 18),
          ]),
        ),
      );
    });
  }
}
