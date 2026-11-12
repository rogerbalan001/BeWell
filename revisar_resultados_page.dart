import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';
import '../widgets/selector_clasificacion.dart';

/// El paciente revisa la categoría y el tipo que sugirió la app (o los elige si no hubo
/// sugerencia) y corrige los valores detectados antes de guardarlos.
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
  late final Future<List<CategoriaCatalogo>> _categorias = sl<ClasificarExamen>().categorias();
  late EleccionClasificacion _eleccion = EleccionClasificacion(
    categoria: widget.examen?.clasificacion?.categoria,
    tipo: widget.examen?.clasificacion?.tipo ?? '',
  );
  bool _guardando = false;

  List<ResultadoAnalito> get _resultados => [
        for (final f in _filas)
          if (f.analito.text.trim().isNotEmpty && f.valor.text.trim().isNotEmpty)
            ResultadoAnalito(analito: f.analito.text.trim(), valor: f.valor.text.trim(), unidad: f.unidad.text.trim(), rangoReferencia: f.rango.text.trim()),
      ];

  Future<void> _guardar() async {
    final e = widget.examen!;
    if (!_eleccion.completa) {
      mostrarMensaje(context, 'Elige la categoría y el tipo del examen', error: true);
      return;
    }
    final resultados = _resultados;
    setState(() => _guardando = true);
    final error = await intentar(() async {
      if (_eleccion.cambiaRespectoDe(e.clasificacion)) {
        await sl<ClasificarExamen>()(e.id, categoria: _eleccion.categoria!, tipo: _eleccion.tipo);
      }
      // Sin valores detectados ni agregados, el examen queda como adjunto: no hay nada que confirmar.
      if (resultados.isNotEmpty || e.estadoExtraccion == 'EXTRAIDO') {
        await sl<ConfirmarResultados>()(e.id, resultados);
      }
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarMensaje(context, error ?? 'Examen guardado en tu expediente', error: error != null);
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
            antetitulo: 'Revisión del examen',
            titulo: e.titulo,
            descripcion: _filas.isEmpty
                ? 'Confirma la categoría y el tipo. No detectamos valores: puedes agregarlos a mano o guardar el examen como adjunto.'
                : 'Confirma la categoría y el tipo, y corrige cualquier valor mal leído. Los valores con confianza baja están marcados en ámbar.',
          ),
          SeccionTarjeta(
            titulo: 'Categoría y tipo',
            icono: Icons.category_outlined,
            child: FutureBuilder<List<CategoriaCatalogo>>(
              future: _categorias,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text('No se pudo cargar el catálogo de exámenes.', style: TextStyle(color: Theme.of(context).colorScheme.error));
                }
                if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                return SelectorClasificacion(
                  categorias: snap.data!,
                  inicial: e.clasificacion,
                  alCambiar: (eleccion) => setState(() => _eleccion = eleccion),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SeccionTarjeta(
            titulo: 'Valores',
            icono: Icons.science_outlined,
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
                    IconButton(
                      tooltip: 'Quitar valor',
                      onPressed: () => setState(() => _filas.remove(f)),
                      icon: const Icon(Icons.delete_outline),
                    ),
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
            icon: _guardando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar y guardar'),
          ),
        ]),
      ),
    );
  }
}
