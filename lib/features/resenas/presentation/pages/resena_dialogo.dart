import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/resena.dart';
import '../../domain/usecases/resenas_usecases.dart';
import '../widgets/estrellas.dart';

/// Formulario de reseña (4 criterios de 1 a 5 + comentario opcional).
/// Devuelve true si se publicó o editó.
Future<bool> mostrarDialogoResena(BuildContext context, {required String citaId, Resena? existente}) async {
  final r = await showDialog<bool>(context: context, builder: (_) => _DialogoResena(citaId: citaId, existente: existente));
  return r ?? false;
}

class _DialogoResena extends StatefulWidget {
  const _DialogoResena({required this.citaId, this.existente});
  final String citaId;
  final Resena? existente;
  @override
  State<_DialogoResena> createState() => _DialogoResenaState();
}

class _DialogoResenaState extends State<_DialogoResena> {
  late int _puntualidad = widget.existente?.puntualidad ?? 5;
  late int _trato = widget.existente?.trato ?? 5;
  late int _claridad = widget.existente?.claridad ?? 5;
  late int _instalaciones = widget.existente?.instalaciones ?? 5;
  late final _comentario = TextEditingController(text: widget.existente?.comentario ?? '');
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final c = Calificaciones(puntualidad: _puntualidad, trato: _trato, claridad: _claridad, instalaciones: _instalaciones, comentario: _comentario.text.trim());
    final publicar = sl<PublicarResena>();
    final error = await intentar(() async {
      if (widget.existente == null) {
        await publicar(widget.citaId, c);
      } else {
        await publicar.editar(widget.existente!.id, c);
      }
    });
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existente == null ? 'Califica tu consulta' : 'Editar reseña'),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SelectorEstrellas(etiqueta: 'Puntualidad', valor: _puntualidad, alCambiar: (v) => setState(() => _puntualidad = v)),
          SelectorEstrellas(etiqueta: 'Trato', valor: _trato, alCambiar: (v) => setState(() => _trato = v)),
          SelectorEstrellas(etiqueta: 'Claridad', valor: _claridad, alCambiar: (v) => setState(() => _claridad = v)),
          SelectorEstrellas(etiqueta: 'Instalaciones', valor: _instalaciones, alCambiar: (v) => setState(() => _instalaciones = v)),
          const SizedBox(height: 8),
          TextField(controller: _comentario, maxLines: 3, maxLength: 1000, decoration: const InputDecoration(labelText: 'Comentario (opcional)')),
          const Text('Solo los pacientes con una consulta atendida pueden reseñar. Podrás editarla durante 7 días.',
              style: TextStyle(fontSize: 12)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: _enviando ? null : _enviar, child: const Text('Publicar')),
      ],
    );
  }
}
