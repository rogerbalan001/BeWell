import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'terminologia.dart';

/// Buscador de diagnósticos CIE-10: se escribe el código o parte del nombre y se elige de la lista.
/// Los diagnósticos elegidos se muestran como chips que se pueden quitar.
class BuscadorCie10 extends StatefulWidget {
  const BuscadorCie10({super.key, required this.valores, required this.alCambiar, this.etiqueta = 'Buscar diagnóstico CIE-10 *'});
  final List<String> valores;
  final ValueChanged<List<String>> alCambiar;
  final String etiqueta;

  @override
  State<BuscadorCie10> createState() => _BuscadorCie10State();
}

class _BuscadorCie10State extends State<BuscadorCie10> {
  final _texto = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valores = widget.valores;
    final alCambiar = widget.alCambiar;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RawAutocomplete<CodigoCie10>(
        textEditingController: _texto,
        focusNode: _foco,
        optionsBuilder: (v) => buscarCie10(v.text),
        displayStringForOption: (c) => c.etiqueta,
        onSelected: (c) {
          if (!valores.contains(c.etiqueta)) alCambiar([...valores, c.etiqueta]);
          _texto.clear();
        },
        fieldViewBuilder: (context, controlador, foco, alEnviar) => TextField(
          controller: controlador,
          focusNode: foco,
          decoration: AppTheme.campo(widget.etiqueta, ayuda: 'Escribe el código (p. ej. I10) o parte del nombre (p. ej. hipertensión)')
              .copyWith(prefixIcon: const Icon(Icons.search)),
        ),
        optionsViewBuilder: (context, alElegir, opciones) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final c in opciones)
                    ListTile(
                      dense: true,
                      leading: Text(c.codigo, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primario)),
                      title: Text(c.descripcion),
                      onTap: () => alElegir(c),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (valores.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in valores)
            InputChip(
              avatar: Icon(tieneCodigoCie10(v) ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  size: 16, color: tieneCodigoCie10(v) ? AppColors.verdeOscuro : AppColors.ambar),
              label: Text(v),
              onDeleted: () => alCambiar(valores.where((x) => x != v).toList()),
            ),
        ]),
      ],
    ]);
  }
}
