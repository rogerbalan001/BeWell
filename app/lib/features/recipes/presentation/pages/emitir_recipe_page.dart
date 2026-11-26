import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/clinico/buscador_cie10.dart';
import '../../../../core/clinico/terminologia.dart';
import '../../../../core/theme/app_textos.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../citas/domain/entities/cita.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/recipes_usecases.dart';
import 'recipe_widgets.dart';

/// HU: emitir un récipe con datos del médico, paciente, medicamentos, dosis, firma y código.
class EmitirRecipePage extends StatefulWidget {
  const EmitirRecipePage({super.key, required this.citaId, this.cita});
  final String citaId;
  final Cita? cita;

  @override
  State<EmitirRecipePage> createState() => _EmitirRecipePageState();
}

class _ItemForm {
  final medicamento = TextEditingController();
  final presentacion = TextEditingController();
  final cantidad = TextEditingController();
  String unidad = 'mg';
  String frecuencia = 'cada 8 horas';
  String via = 'Vía oral';
  final dias = TextEditingController(text: '7');
  final indicaciones = TextEditingController();

  bool get vacio => medicamento.text.trim().isEmpty && cantidad.text.trim().isEmpty;

  /// Dosis con cantidad y unidad estandarizada (p. ej. "500 mg"); null si falta o no es válida.
  String? get dosis {
    final n = double.tryParse(cantidad.text.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return null;
    final d = componerDosis(cantidad.text, unidad);
    return dosisValida(d) ? d : null;
  }

  ItemRecipe? aItem() {
    final d = dosis;
    if (medicamento.text.trim().isEmpty || d == null) return null;
    final extra = indicaciones.text.trim();
    return ItemRecipe(
      medicamento: medicamento.text.trim(),
      presentacion: presentacion.text.trim(),
      dosis: d,
      frecuencia: frecuencia,
      duracionDias: int.tryParse(dias.text.trim()) ?? 1,
      indicaciones: extra.isEmpty ? '$via.' : '$via. $extra',
    );
  }
}

class _EmitirRecipePageState extends State<EmitirRecipePage> {
  final List<_ItemForm> _items = [_ItemForm()];
  List<String> _diagnosticos = const [];
  int _vigencia = 30;
  bool _enviando = false;

  Future<void> _emitir() async {
    final llenos = _items.where((i) => !i.vacio).toList();
    final items = llenos.map((i) => i.aItem()).whereType<ItemRecipe>().toList();
    if (llenos.isEmpty || items.length != llenos.length) {
      mostrarMensaje(context, 'Cada medicamento necesita nombre y una dosis con cantidad y unidad válida (mg, ml, UI…)', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      final r = await sl<EmitirRecipe>()(citaId: widget.citaId, items: items, diagnostico: _diagnosticos.join('; '), validoDias: _vigencia);
      if (!mounted) return;
      mostrarMensaje(context, 'Récipe ${r.codigo} firmado y guardado en el expediente del paciente');
      await mostrarRecipeConQr(context, r);
      if (mounted) context.pop();
    } on Failure catch (f) {
      if (mounted) mostrarMensaje(context, f.mensaje, error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  InputDecoration _d(String l) => AppTheme.campo(l);

  @override
  Widget build(BuildContext context) {
    final c = widget.cita;
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 860,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Encabezado(
            antetitulo: 'Récipe digital firmado',
            titulo: 'Emitir récipe',
            descripcion: c == null ? null : 'Paciente: ${c.pacienteNombre} · consulta #${c.codigo}',
          ),
          BuscadorCie10(valores: _diagnosticos, alCambiar: (v) => setState(() => _diagnosticos = v), etiqueta: 'Diagnóstico CIE-10 (opcional)'),
          const SizedBox(height: 14),
          for (var i = 0; i < _items.length; i++)
            Padding(
              key: ObjectKey(_items[i]),
              padding: const EdgeInsets.only(bottom: 12),
              child: SeccionTarjeta(
                titulo: 'Medicamento ${i + 1}',
                icono: Icons.medication_outlined,
                accion: _items.length > 1 ? IconButton(onPressed: () => setState(() => _items.removeAt(i)), icon: const Icon(Icons.delete_outline)) : null,
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextField(controller: _items[i].medicamento, decoration: _d('Medicamento'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _items[i].presentacion, decoration: _d('Presentación (p. ej. Tab 500 mg)'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _items[i].cantidad,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _d('Dosis'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        initialValue: _items[i].unidad,
                        decoration: _d('Unidad'),
                        items: [for (final u in unidadesDosis) DropdownMenuItem(value: u, child: Text(u))],
                        onChanged: (v) => setState(() => _items[i].unidad = v ?? _items[i].unidad),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _items[i].frecuencia,
                        isExpanded: true,
                        decoration: _d('Frecuencia'),
                        items: [for (final f in frecuenciasEstandar) DropdownMenuItem(value: f, child: Text(f))],
                        onChanged: (v) => setState(() => _items[i].frecuencia = v ?? _items[i].frecuencia),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(width: 90, child: TextField(controller: _items[i].dias, keyboardType: TextInputType.number, decoration: _d('Días'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: _items[i].via,
                        isExpanded: true,
                        decoration: _d('Vía'),
                        items: [for (final v in viasAdministracion) DropdownMenuItem(value: v, child: Text(v))],
                        onChanged: (v) => setState(() => _items[i].via = v ?? _items[i].via),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _items[i].indicaciones, decoration: _d('Indicaciones (opcional)'))),
                  ]),
                ]),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: () => setState(() => _items.add(_ItemForm())), icon: const Icon(Icons.add), label: const Text('Agregar medicamento')),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Vigencia:', style: AppTextos.enfasisSuave),
            for (final d in const [7, 15, 30, 60, 90]) ChoiceChip(label: Text('$d días'), selected: _vigencia == d, onSelected: (_) => setState(() => _vigencia = d)),
          ]),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _enviando ? null : _emitir,
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Firmar y emitir récipe'),
          ),
        ]),
      ),
    );
  }
}
