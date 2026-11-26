import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_textos.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';
import '../pages/resultados_widget.dart';

/// Exámenes con valores confirmados por el paciente que el médico todavía no valida.
List<Examen> pendientesDeValidar(List<Examen> examenes) =>
    examenes.where((e) => e.estadoExtraccion == 'CONFIRMADO' && !e.validadoPorMedico && e.resultados.isNotEmpty).toList()
      ..sort((a, b) => b.cargadoEn.compareTo(a.cargadoEn));

/// HU médico: ver los resultados pendientes de validar del paciente y confirmarlos desde la app.
class ResultadosPorValidar extends StatefulWidget {
  const ResultadosPorValidar({super.key, required this.pacienteId});
  final String pacienteId;

  @override
  State<ResultadosPorValidar> createState() => _ResultadosPorValidarState();
}

class _ResultadosPorValidarState extends State<ResultadosPorValidar> {
  List<Examen>? _examenes;
  String? _error;
  String? _validando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await sl<ListarExamenes>()(widget.pacienteId);
      if (mounted) setState(() => _examenes = lista);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los resultados del paciente.');
    }
  }

  Future<void> _validar(Examen e) async {
    setState(() => _validando = e.id);
    final error = await intentar(() => sl<ConfirmarResultados>().validarComoMedico(e.id));
    if (!mounted) return;
    setState(() => _validando = null);
    mostrarMensaje(context, error ?? 'Resultados validados. El paciente ya los ve como validados.', error: error != null);
    if (error == null) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final examenes = _examenes;
    if (_error != null) return Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_error!, style: AppTextos.secundario));
    if (examenes == null) return const SizedBox.shrink();
    final pendientes = pendientesDeValidar(examenes);
    final validados = examenes.where((e) => e.validadoPorMedico).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SeccionTarjeta(
        icono: Icons.fact_check_outlined,
        titulo: 'Resultados por validar',
        subtitulo: pendientes.isEmpty
            ? 'No hay resultados pendientes. Validados hasta ahora: $validados.'
            : '${pendientes.length} examen(es) con valores confirmados por el paciente. Validados hasta ahora: $validados.',
        child: pendientes.isEmpty
            ? const Text('Cuando el paciente suba y confirme los valores de un examen, aparecerán aquí para que los revises.',
                style: AppTextos.secundario)
            : Column(children: [
                for (final e in pendientes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.titulo, style: AppTextos.tituloTarjeta),
                            Text('Subido el ${Formatos.fechaCorta(e.fechaExamen ?? e.cargadoEn)}', style: AppTextos.secundario),
                          ]),
                        ),
                        FilledButton.icon(
                          onPressed: _validando == null ? () => _validar(e) : null,
                          icon: _validando == e.id
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.verified_outlined),
                          label: const Text('Validar resultados'),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      TablaResultados(resultados: e.resultados),
                    ]),
                  ),
                const Text('Al validar, cada valor queda marcado con el sello verde de "Validado por médico" en los exámenes del paciente.',
                    style: TextStyle(fontSize: 12, color: AppColors.pizarraClara)),
              ]),
      ),
    );
  }
}
