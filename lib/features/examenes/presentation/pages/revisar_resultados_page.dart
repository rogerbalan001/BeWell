import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';

/// El paciente revisa y corrige los valores detectados antes de guardarlos.
class RevisarResultadosPage extends StatefulWidget {
  const RevisarResultadosPage({super.key, required this.examen});
  final Examen? examen;

  @override
  State<RevisarResultadosPage> createState() => _RevisarResultadosPageState();
}

class _Fila {
  _Fila(ResultadoAnalito? r)
      : analito = TextEditingController(text: r?.analito ?? ''),
        valor = TextEditingController(text: r?.valor ?? ''),
        unidad = TextEditingController(text: r?.unidad ?? ''),
        rango = TextEditingController(text: r?.rangoReferencia ?? ''),
        confianza = r?.confianzaOcr;
  final TextEditingController analito, valor, unidad, rango;
  final double? confianza;
}

class _RevisarResultadosPageState extends State<RevisarResultadosPage> {
  late final List<_Fila> _filas = (widget.examen?.resultados ?? const <ResultadoAnalito>[]).map(_Fila.new).toList();
  bool _guardando = false;

  Future<void> _guardar() async {
    final resultados = [
      for (final f in _filas)
        if (f.analito.text.trim().isNotEmpty && f.valor.text.trim().isNotEmpty)
          ResultadoAnalito(analito: f.analito.text.trim(), valor: f.valor.text.trim(), unidad: f.unidad.text.trim(), rangoReferencia: f.rango.text.trim()),
    ];
    setState(() => _guardando = true);
    final error = await intentar(() => sl<ConfirmarResultados>()(widget.examen!.id, resultados));
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarMensaje(context, error ?? 'Valores guardados en tu expediente', error: error != null);
    if (error == null) context.pop();
  }

  InputDecoration _deco(String l) => InputDecoration(labelText: l, isDense: true, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) {
    final e = widget.examen;
    if (e == null) return const VistaVacia(icono: Icons.search_off, titulo: 'Examen no encontrado');
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 960,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Encabezado(
            antetitulo: 'Revisión de valores',
            titulo: e.titulo,
            descripcion: 'Corrige cualquier valor mal leído. Los valores con confianza baja están marcados en ámbar.',
          ),
          BwTarjeta(
            child: Column(children: [
              for (final f in _filas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    SizedBox(width: 220, child: TextField(controller: f.analito, decoration: _deco('Analito'))),
                    SizedBox(width: 110, child: TextField(controller: f.valor, decoration: _deco('Valor'))),
                    SizedBox(width: 100, child: TextField(controller: f.unidad, decoration: _deco('Unidad'))),
                    SizedBox(width: 160, child: TextField(controller: f.rango, decoration: _deco('Rango ref.'))),
                    if (f.confianza != null)
                      ChipEstado('${(f.confianza! * 100).round()} %', color: f.confianza! < 0.85 ? AppColors.ambar : AppColors.verde),
                    IconButton(onPressed: () => setState(() => _filas.remove(f)), icon: const Icon(Icons.delete_outline)),
                  ]),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(onPressed: () => setState(() => _filas.add(_Fila(null))), icon: const Icon(Icons.add), label: const Text('Agregar valor')),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar y guardar valores'),
          ),
        ]),
      ),
    );
  }
}
