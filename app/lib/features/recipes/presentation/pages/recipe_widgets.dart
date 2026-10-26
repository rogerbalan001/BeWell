import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/recipe.dart';

class ListaItemsRecipe extends StatelessWidget {
  const ListaItemsRecipe(this.items, {super.key});
  final List<ItemRecipe> items;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (final i in items)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.medication_outlined, color: AppColors.primario),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i.medicamento} ${i.presentacion}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${i.dosis} · ${i.frecuencia} · ${i.duracionDias} días', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
                if (i.indicaciones != null) Text(i.indicaciones!, style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
              ]),
            ),
          ]),
        ),
    ]);
  }
}

/// Récipe con su QR de verificación para mostrar en la farmacia.
Future<void> mostrarRecipeConQr(BuildContext context, Recipe r) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const BwLogo(tamano: 28),
              const Spacer(),
              ChipEstado(r.vigente ? 'Vigente' : (r.estado == 'ANULADO' ? 'Anulado' : 'Vencido'), color: r.vigente ? AppColors.verde : AppColors.error),
            ]),
            const SizedBox(height: 14),
            Text('Récipe ${r.codigo}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('${r.medicoNombre} · ${r.especialidad}', style: const TextStyle(color: AppColors.pizarra)),
            Text('Paciente: ${r.pacienteNombre}', style: const TextStyle(color: AppColors.pizarra)),
            Text('Emitido ${Formatos.fechaCorta(r.emitidoEn)} · válido hasta ${Formatos.fechaCorta(r.validoHasta)}',
                style: const TextStyle(color: AppColors.pizarra, fontSize: 12.5)),
            if (r.diagnostico != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Dx: ${r.diagnostico}')),
            const SizedBox(height: 12),
            ListaItemsRecipe(r.items),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borde)),
                child: QrImageView(data: r.urlVerificacion, version: QrVersions.auto, size: 190),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: SelectableText(r.codigo, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 16))),
            const SizedBox(height: 4),
            const Center(
              child: Text('La farmacia escanea el QR o ingresa el código para verificar la firma digital.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.pizarra)),
            ),
            const SizedBox(height: 8),
            Text('Firma ${r.algoritmo} · SHA-256 ${r.hash.substring(0, r.hash.length < 16 ? r.hash.length : 16)}…',
                style: const TextStyle(fontSize: 11, color: AppColors.pizarraClara)),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
    ),
  );
}
