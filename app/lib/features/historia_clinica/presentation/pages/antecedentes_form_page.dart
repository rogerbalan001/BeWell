import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';
import '../widgets/historia_widgets.dart';

/// Formulario de antecedentes de la historia clínica. Devuelve true al guardar.
class AntecedentesFormPage extends StatefulWidget {
  const AntecedentesFormPage({
    super.key,
    required this.pacienteId,
    required this.inicial,
    required this.femenino,
    required this.autoReportado,
  });
  final String pacienteId;
  final Antecedentes inicial;
  final bool femenino;

  /// true si lo llena el propio paciente (dato auto-reportado).
  final bool autoReportado;

  @override
  State<AntecedentesFormPage> createState() => _AntecedentesFormPageState();
}

class _AntecedentesFormPageState extends State<AntecedentesFormPage> {
  late String? _grupo = widget.inicial.grupoSanguineo;
  late List<String> _alergicos = widget.inicial.alergicos;
  late List<String> _patologicos = widget.inicial.patologicos;
  late List<String> _medicamentos = widget.inicial.medicamentosActuales;
  late List<String> _quirurgicos = widget.inicial.quirurgicos;
  late List<String> _hospitalizaciones = widget.inicial.hospitalizaciones;
  late List<String> _inmunizaciones = widget.inicial.inmunizaciones;
  late List<String> _familiares = widget.inicial.familiares;
  late final Map<String, TextEditingController> _habitos = {
    for (final k in habitosLegibles.keys) k: TextEditingController(text: widget.inicial.habitos[k] ?? ''),
  };

  late final GinecoObstetricos? _g = widget.inicial.ginecoObstetricos;
  late final _menarquia = TextEditingController(text: _g?.menarquia ?? '');
  late final _fum = TextEditingController(text: _g?.ultimaMenstruacion ?? '');
  late final _gestas = TextEditingController(text: _g?.gestas?.toString() ?? '');
  late final _partos = TextEditingController(text: _g?.partos?.toString() ?? '');
  late final _cesareas = TextEditingController(text: _g?.cesareas?.toString() ?? '');
  late final _abortos = TextEditingController(text: _g?.abortos?.toString() ?? '');
  late final _anticonceptivo = TextEditingController(text: _g?.metodoAnticonceptivo ?? '');

  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [..._habitos.values, _menarquia, _fum, _gestas, _partos, _cesareas, _abortos, _anticonceptivo]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texto(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  int? _entero(TextEditingController c) => int.tryParse(c.text.trim());

  GinecoObstetricos? _gineco() {
    if (!widget.femenino) return null;
    final g = GinecoObstetricos(
      menarquia: _texto(_menarquia),
      ultimaMenstruacion: _texto(_fum),
      gestas: _entero(_gestas),
      partos: _entero(_partos),
      cesareas: _entero(_cesareas),
      abortos: _entero(_abortos),
      metodoAnticonceptivo: _texto(_anticonceptivo),
    );
    return g.aJson().isEmpty ? null : g;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final antecedentes = Antecedentes(
      grupoSanguineo: _grupo,
      alergicos: _alergicos,
      patologicos: _patologicos,
      medicamentosActuales: _medicamentos,
      quirurgicos: _quirurgicos,
      hospitalizaciones: _hospitalizaciones,
      inmunizaciones: _inmunizaciones,
      familiares: _familiares,
      habitos: {
        for (final e in _habitos.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      },
      ginecoObstetricos: _gineco(),
    );
    final error = await intentar(() => sl<ActualizarAntecedentesClinicos>()(widget.pacienteId, antecedentes));
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, 'Antecedentes guardados');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    Widget bloque(String titulo, IconData icono, List<Widget> hijos) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SeccionTarjeta(
            titulo: titulo,
            icono: icono,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < hijos.length; i++) ...[if (i > 0) const SizedBox(height: 14), hijos[i]],
            ]),
          ),
        );
    Widget numero(TextEditingController c, String etiqueta) => SizedBox(
          width: 110,
          child: TextField(controller: c, keyboardType: TextInputType.number, decoration: AppTheme.campo(etiqueta)),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antecedentes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'Guardando…' : 'Guardar')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.autoReportado)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Estos datos los reportas tú y los ven los médicos que autorices. Escribe un elemento y pulsa + o Enter para agregarlo.',
                  style: TextStyle(color: AppColors.pizarra),
                ),
              ),
            bloque('Datos generales', Icons.bloodtype_outlined, [
              const Text('Grupo sanguíneo', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ChoiceChip(label: const Text('No sé'), selected: _grupo == null, onSelected: (_) => setState(() => _grupo = null)),
                for (final g in gruposSanguineos) ChoiceChip(label: Text(g), selected: _grupo == g, onSelected: (_) => setState(() => _grupo = g)),
              ]),
              EditorLista(
                etiqueta: 'Alergias',
                ayuda: 'Medicamentos, alimentos u otras (p. ej. "Penicilina — urticaria")',
                valores: _alergicos,
                alCambiar: (v) => setState(() => _alergicos = v),
              ),
            ]),
            bloque('Antecedentes personales', Icons.person_outline, [
              EditorLista(
                etiqueta: 'Enfermedades (patológicos)',
                ayuda: 'P. ej. "Hipertensión arterial desde 2019"',
                valores: _patologicos,
                alCambiar: (v) => setState(() => _patologicos = v),
              ),
              EditorLista(
                etiqueta: 'Medicamentos actuales',
                ayuda: 'Nombre, dosis y frecuencia',
                valores: _medicamentos,
                alCambiar: (v) => setState(() => _medicamentos = v),
              ),
              EditorLista(etiqueta: 'Cirugías (quirúrgicos)', valores: _quirurgicos, alCambiar: (v) => setState(() => _quirurgicos = v)),
              EditorLista(etiqueta: 'Hospitalizaciones', valores: _hospitalizaciones, alCambiar: (v) => setState(() => _hospitalizaciones = v)),
              EditorLista(etiqueta: 'Inmunizaciones', valores: _inmunizaciones, alCambiar: (v) => setState(() => _inmunizaciones = v)),
            ]),
            bloque('Antecedentes familiares', Icons.family_restroom, [
              EditorLista(
                etiqueta: 'Enfermedades en la familia',
                ayuda: 'P. ej. "Madre: diabetes tipo 2"',
                valores: _familiares,
                alCambiar: (v) => setState(() => _familiares = v),
              ),
            ]),
            bloque('Hábitos', Icons.self_improvement, [
              for (final e in habitosLegibles.entries)
                TextField(controller: _habitos[e.key], decoration: AppTheme.campo(e.value)),
            ]),
            if (widget.femenino)
              bloque('Gineco-obstétricos', Icons.pregnant_woman, [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  numero(_gestas, 'Gestas'),
                  numero(_partos, 'Partos'),
                  numero(_cesareas, 'Cesáreas'),
                  numero(_abortos, 'Abortos'),
                ]),
                TextField(controller: _menarquia, decoration: AppTheme.campo('Menarquia (edad)')),
                TextField(controller: _fum, decoration: AppTheme.campo('Fecha de última menstruación (FUM)')),
                TextField(controller: _anticonceptivo, decoration: AppTheme.campo('Método anticonceptivo')),
              ]),
          ]),
        ),
      ),
    );
  }
}
