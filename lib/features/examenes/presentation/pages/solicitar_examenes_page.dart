import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';

/// HU médico: seleccionar exámenes de un catálogo y generar la orden (queda "pendiente").
class SolicitarExamenesPage extends StatefulWidget {
  const SolicitarExamenesPage({super.key, required this.pacienteId, this.citaId, this.pacienteNombre});
  final String pacienteId;
  final String? citaId;
  final String? pacienteNombre;

  @override
  State<SolicitarExamenesPage> createState() => _SolicitarExamenesPageState();
}

class _SolicitarExamenesPageState extends State<SolicitarExamenesPage> {
  List<CategoriaCatalogo>? _catalogo;
  final Set<String> _elegidos = {};
  final _indicaciones = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    sl<SolicitarExamenes>().catalogo().then((c) {
      if (mounted) setState(() => _catalogo = c);
    }).catchError((_) {
      if (mounted) setState(() => _catalogo = const []);
    });
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final error = await intentar(() => sl<SolicitarExamenes>()(
          pacienteId: widget.pacienteId,
          examenes: _elegidos.toList(),
          indicaciones: _indicaciones.text.trim(),
          citaId: widget.citaId,
        ));
    if (!mounted) return;
    setState(() => _enviando = false);
    mostrarMensaje(context, error ?? 'Orden generada: quedó en el expediente con estado "pendiente"', error: error != null);
    if (error == null) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = _catalogo;
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 860,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Encabezado(antetitulo: 'Orden médica', titulo: 'Solicitar exámenes', descripcion: 'Paciente: ${widget.pacienteNombre ?? ''}'),
          if (catalogo == null)
            const VistaCargando()
          else
            for (final c in catalogo)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SeccionTarjeta(
                  titulo: c.categoria,
                  child: Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final e in c.examenes)
                      FilterChip(
                        label: Text(e),
                        selected: _elegidos.contains(e),
                        onSelected: (s) => setState(() => s ? _elegidos.add(e) : _elegidos.remove(e)),
                      ),
                  ]),
                ),
              ),
          TextField(controller: _indicaciones, maxLines: 3, decoration: AppTheme.campo('Indicaciones (p. ej. ayuno de 12 horas)')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _enviando || _elegidos.isEmpty ? null : _enviar,
            icon: const Icon(Icons.send),
            label: Text('Generar orden (${_elegidos.length})'),
          ),
        ]),
      ),
    );
  }
}
