import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final dosis = TextEditingController();
  final frecuencia = TextEditingController();
  final dias = TextEditingController(text: '7');
  final indicaciones = TextEditingController();

  ItemRecipe? aItem() {
    if (medicamento.text.trim().isEmpty || dosis.text.trim().isEmpty || frecuencia.text.trim().isEmpty) return null;
    return ItemRecipe(
      medicamento: medicamento.text.trim(),
      presentacion: presentacion.text.trim(),
      dosis: dosis.text.trim(),
      frecuencia: frecuencia.text.trim(),
      duracionDias: int.tryParse(dias.text.trim()) ?? 1,
      indicaciones: indicaciones.text.trim(),
    );
  }
}

class _EmitirRecipePageState extends State<EmitirRecipePage> {
  final List<_ItemForm> _items = [_ItemForm()];
  final _diagnostico = TextEditingController();
  int _vigencia = 30;
  bool _enviando = false;

  Future<void> _emitir() async {
    final items = _items.map((i) => i.aItem()).whereType<ItemRecipe>().toList();
    if (items.isEmpty) {
      mostrarMensaje(context, 'Completa al menos un medicamento (nombre, dosis y frecuencia)', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      final r = await sl<EmitirRecipe>()(citaId: widget.citaId, items: items, diagnostico: _diagnostico.text.trim(), validoDias: _vigencia);
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
          TextField(controller: _diagnostico, decoration: _d('Diagnóstico (opcional)')),
          const SizedBox(height: 14),
          for (var i = 0; i < _items.length; i++)
            Padding(
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
                    Expanded(child: TextField(controller: _items[i].dosis, decoration: _d('Dosis'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _items[i].frecuencia, decoration: _d('Frecuencia'))),
                    const SizedBox(width: 10),
                    SizedBox(width: 110, child: TextField(controller: _items[i].dias, keyboardType: TextInputType.number, decoration: _d('Días'))),
                  ]),
                  const SizedBox(height: 10),
                  TextField(controller: _items[i].indicaciones, decoration: _d('Indicaciones (opcional)')),
                ]),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: () => setState(() => _items.add(_ItemForm())), icon: const Icon(Icons.add), label: const Text('Agregar medicamento')),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            const Text('Vigencia:', style: TextStyle(fontWeight: FontWeight.w600)),
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
