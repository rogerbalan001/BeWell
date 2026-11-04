import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';

/// Opción del menú de tipos para escribir uno que no está en el catálogo.
const opcionOtroTipo = 'Otro (escribir)';

/// Categoría y tipo que el paciente tiene elegidos en pantalla.
class EleccionClasificacion {
  const EleccionClasificacion({this.categoria, this.tipo = ''});
  final String? categoria;
  final String tipo;

  bool get completa => (categoria ?? '').isNotEmpty && tipo.trim().isNotEmpty;

  /// Si difiere de lo guardado (o no había nada guardado), hay que enviarlo a la API.
  bool cambiaRespectoDe(ClasificacionExamen? guardada) =>
      guardada == null || guardada.categoria != categoria || guardada.tipo != tipo.trim();
}

/// Muestra la sugerencia de la app (con su confianza) y deja corregir la categoría y el tipo.
/// Si no hubo sugerencia, pide que el paciente los elija.
class SelectorClasificacion extends StatefulWidget {
  const SelectorClasificacion({super.key, required this.categorias, required this.inicial, required this.alCambiar});

  /// Categorías del catálogo con sus exámenes (incluye "Otro").
  final List<CategoriaCatalogo> categorias;
  final ClasificacionExamen? inicial;
  final ValueChanged<EleccionClasificacion> alCambiar;

  @override
  State<SelectorClasificacion> createState() => _SelectorClasificacionState();
}

class _SelectorClasificacionState extends State<SelectorClasificacion> {
  String? _categoria;
  String? _tipoMenu;
  late final TextEditingController _tipoLibre;

  List<String> _tiposDe(String? categoria) =>
      widget.categorias.firstWhere((c) => c.categoria == categoria, orElse: () => const CategoriaCatalogo('', [])).examenes;

  bool get _escribeTipo => _categoria == categoriaOtro || _tiposDe(_categoria).isEmpty || _tipoMenu == opcionOtroTipo;

  @override
  void initState() {
    super.initState();
    final c = widget.inicial;
    final existe = widget.categorias.any((x) => x.categoria == c?.categoria);
    _categoria = existe ? c!.categoria : (c == null ? null : categoriaOtro);
    final tipos = _tiposDe(_categoria);
    _tipoMenu = c == null ? null : (tipos.contains(c.tipo) ? c.tipo : opcionOtroTipo);
    _tipoLibre = TextEditingController(text: c != null && !tipos.contains(c.tipo) ? c.tipo : '');
  }

  @override
  void dispose() {
    _tipoLibre.dispose();
    super.dispose();
  }

  void _avisar() {
    final tipo = _escribeTipo ? _tipoLibre.text : (_tipoMenu ?? '');
    widget.alCambiar(EleccionClasificacion(categoria: _categoria, tipo: tipo.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.inicial;
    final textos = Theme.of(context).textTheme;
    final tipos = _tiposDe(_categoria);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (c != null && c.sugeridaPorIa)
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ChipEstado('Sugerido por la app${c.confianzaLegible != null ? ' · ${c.confianzaLegible}' : ''}', color: AppColors.primario, icono: Icons.auto_awesome),
          Text('Corrígelo si no es correcto.', style: textos.bodySmall?.copyWith(color: AppColors.pizarra)),
        ])
      else if (c == null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.ambarSuave, borderRadius: BorderRadius.circular(14)),
          child: Text(
            'No pudimos reconocer el tipo de examen. Elige la categoría y el tipo para encontrarlo fácil en tu expediente.',
            style: textos.bodyMedium?.copyWith(color: AppColors.ambar),
          ),
        ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: const Key('categoria-examen'),
        initialValue: _categoria,
        decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
        items: [for (final cat in widget.categorias) DropdownMenuItem(value: cat.categoria, child: Text(cat.categoria))],
        onChanged: (v) {
          setState(() {
            _categoria = v;
            _tipoMenu = null;
          });
          _avisar();
        },
      ),
      const SizedBox(height: 12),
      if (tipos.isNotEmpty && _categoria != categoriaOtro)
        DropdownButtonFormField<String>(
          key: ValueKey('tipo-examen-$_categoria'),
          initialValue: _tipoMenu,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de examen', border: OutlineInputBorder()),
          items: [
            for (final t in tipos) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)),
            const DropdownMenuItem(value: opcionOtroTipo, child: Text(opcionOtroTipo)),
          ],
          onChanged: (v) {
            setState(() => _tipoMenu = v);
            _avisar();
          },
        ),
      if (_escribeTipo && _categoria != null) ...[
        if (tipos.isNotEmpty && _categoria != categoriaOtro) const SizedBox(height: 12),
        TextField(
          key: const Key('tipo-examen-libre'),
          controller: _tipoLibre,
          decoration: const InputDecoration(labelText: 'Escribe el tipo de examen', border: OutlineInputBorder()),
          onChanged: (_) => _avisar(),
        ),
      ],
    ]);
  }
}
