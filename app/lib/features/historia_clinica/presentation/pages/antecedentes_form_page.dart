import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';
import '../widgets/historia_widgets.dart';

/// Formulario de antecedentes (secciones III a V del modelo de historia clínica
/// integral, resumidas). Devuelve true al guardar.
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

/// Campo de lista: clave del JSON, etiqueta y ayuda.
typedef _Lista = ({String clave, String etiqueta, String? ayuda});

const _personales = <_Lista>[
  (clave: 'inmunizaciones', etiqueta: 'Inmunizaciones', ayuda: null),
  (clave: 'infancia', etiqueta: 'Enfermedades de la infancia', ayuda: 'Sarampión, varicela, asma, otitis…'),
  (clave: 'alergicos', etiqueta: 'Alergias', ayuda: 'Medicamentos, alimentos u otras (p. ej. "Penicilina — urticaria")'),
  (clave: 'patologicos', etiqueta: 'Médicos', ayuda: 'HTA, diabetes, infecciones, ETS, psiquiátricos…'),
  (clave: 'quirurgicos', etiqueta: 'Quirúrgicos', ayuda: 'Fecha, cirugía y complicaciones'),
  (clave: 'traumatologicos', etiqueta: 'Traumatológicos', ayuda: null),
  (clave: 'transfusionales', etiqueta: 'Transfusionales', ayuda: null),
  (clave: 'epidemiologicos', etiqueta: 'Epidemiológicos', ayuda: 'Viajes, sitios visitados, contacto con animales'),
  (clave: 'medicamentosActuales', etiqueta: 'Medicamentos actuales', ayuda: 'Nombre, dosis y frecuencia'),
];

class _AntecedentesFormPageState extends State<AntecedentesFormPage> {
  late String? _grupo = widget.inicial.grupoSanguineo;
  late final Map<String, List<String>> _listas = {
    'inmunizaciones': widget.inicial.inmunizaciones,
    'infancia': widget.inicial.infancia,
    'alergicos': widget.inicial.alergicos,
    'patologicos': widget.inicial.patologicos,
    'quirurgicos': widget.inicial.quirurgicos,
    'traumatologicos': widget.inicial.traumatologicos,
    'transfusionales': widget.inicial.transfusionales,
    'epidemiologicos': widget.inicial.epidemiologicos,
    'medicamentosActuales': widget.inicial.medicamentosActuales,
    'familiares': widget.inicial.familiares,
  };
  late final Map<String, TextEditingController> _sociales = {
    for (final k in datosSocialesLegibles.keys) k: TextEditingController(text: widget.inicial.datosSociales[k] ?? ''),
  };
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
    for (final c in [..._sociales.values, ..._habitos.values, _menarquia, _fum, _gestas, _partos, _cesareas, _abortos, _anticonceptivo]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texto(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  int? _entero(TextEditingController c) => int.tryParse(c.text.trim());

  Map<String, String> _pares(Map<String, TextEditingController> m) => {
        for (final e in m.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

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
    final l = _listas;
    final antecedentes = Antecedentes(
      grupoSanguineo: _grupo,
      datosSociales: _pares(_sociales),
      inmunizaciones: l['inmunizaciones']!,
      infancia: l['infancia']!,
      alergicos: l['alergicos']!,
      patologicos: l['patologicos']!,
      quirurgicos: l['quirurgicos']!,
      traumatologicos: l['traumatologicos']!,
      transfusionales: l['transfusionales']!,
      epidemiologicos: l['epidemiologicos']!,
      medicamentosActuales: l['medicamentosActuales']!,
      familiares: l['familiares']!,
      habitos: _pares(_habitos),
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

  Widget _lista(_Lista campo) => EditorLista(
        etiqueta: campo.etiqueta,
        ayuda: campo.ayuda,
        valores: _listas[campo.clave]!,
        alCambiar: (v) => setState(() => _listas[campo.clave] = v),
      );

  /// Campos de texto cortos en una rejilla de dos columnas en pantallas anchas.
  Widget _rejilla(Map<String, TextEditingController> controles, Map<String, String> etiquetas) => LayoutBuilder(
        builder: (context, c) {
          final ancho = c.maxWidth >= 560 ? (c.maxWidth - 12) / 2 : c.maxWidth;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final e in etiquetas.entries)
              SizedBox(width: ancho, child: TextField(controller: controles[e.key], decoration: AppTheme.campo(e.value))),
          ]);
        },
      );

  @override
  Widget build(BuildContext context) {
    Widget bloque(String titulo, IconData icono, List<Widget> hijos) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SeccionTarjeta(
            titulo: titulo,
            icono: icono,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.autoReportado
                    ? 'Estos datos los reportas tú y los ven los médicos que autorices. Escribe y pulsa + o Enter para agregar cada elemento; deja vacío lo que no aplique.'
                    : 'Escribe y pulsa + o Enter para agregar cada elemento; deja vacío lo que no aplique.',
                style: const TextStyle(color: AppColors.pizarra),
              ),
            ),
            bloque('Identificación', Icons.badge_outlined, [
              const Text('Grupo sanguíneo', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ChoiceChip(label: const Text('No sé'), selected: _grupo == null, onSelected: (_) => setState(() => _grupo = null)),
                for (final g in gruposSanguineos) ChoiceChip(label: Text(g), selected: _grupo == g, onSelected: (_) => setState(() => _grupo = g)),
              ]),
              _rejilla(_sociales, datosSocialesLegibles),
            ]),
            bloque('III. Antecedentes personales', Icons.person_outline, [for (final c in _personales) _lista(c)]),
            if (widget.femenino)
              bloque('Ginecobstétricos', Icons.pregnant_woman, [
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
            bloque('IV. Antecedentes familiares', Icons.family_restroom, [
              _lista((clave: 'familiares', etiqueta: 'Enfermedades en la familia', ayuda: 'P. ej. "Madre: diabetes tipo 2"')),
            ]),
            bloque('V. Historia personal y social', Icons.self_improvement, [_rejilla(_habitos, habitosLegibles)]),
          ]),
        ),
      ),
    );
  }
}
