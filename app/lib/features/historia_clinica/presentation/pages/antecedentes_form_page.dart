import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/catalogo_historia.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';
import '../widgets/historia_widgets.dart';

/// Formulario de la identificación y los antecedentes (secciones III a V del
/// modelo de historia clínica integral). Devuelve true al guardar.
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
  late final Map<String, List<String>> _personales = {
    for (final (_, c) in antecedentesPersonales) c.clave: widget.inicial.lista(c.clave),
  };
  late final Map<String, List<String>> _familiares = {
    for (final c in antecedentesFamiliares) c.clave: widget.inicial.familiares[c.clave] ?? const [],
  };
  late List<String> _medicamentos = widget.inicial.medicamentosActuales;
  late final Map<String, TextEditingController> _identificacion = {
    for (final c in camposIdentificacion) c.clave: TextEditingController(text: widget.inicial.datosSociales[c.clave] ?? ''),
  };
  late final Map<String, TextEditingController> _habitos = {
    for (final c in habitosCatalogo) c.clave: TextEditingController(text: widget.inicial.habitos[c.clave] ?? ''),
  };

  late final GinecoObstetricos? _g = widget.inicial.ginecoObstetricos;
  late final Map<String, TextEditingController> _gineco = {
    'gestas': TextEditingController(text: _g?.gestas?.toString() ?? ''),
    'partos': TextEditingController(text: _g?.partos?.toString() ?? ''),
    'cesareas': TextEditingController(text: _g?.cesareas?.toString() ?? ''),
    'abortos': TextEditingController(text: _g?.abortos?.toString() ?? ''),
    'perdidasFetales': TextEditingController(text: _g?.perdidasFetales?.toString() ?? ''),
    'menarquia': TextEditingController(text: _g?.menarquia ?? ''),
    'ultimaMenstruacion': TextEditingController(text: _g?.ultimaMenstruacion ?? ''),
    'trastornosMenstruales': TextEditingController(text: _g?.trastornosMenstruales ?? ''),
    'eclampsia': TextEditingController(text: _g?.eclampsia ?? ''),
    'menopausia': TextEditingController(text: _g?.menopausia ?? ''),
    'metodoAnticonceptivo': TextEditingController(text: _g?.metodoAnticonceptivo ?? ''),
  };

  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [..._identificacion.values, ..._habitos.values, ..._gineco.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _pares(Map<String, TextEditingController> m) => {
        for (final e in m.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  GinecoObstetricos? _leerGineco() {
    if (!widget.femenino) return null;
    String? t(String k) => _gineco[k]!.text.trim().isEmpty ? null : _gineco[k]!.text.trim();
    int? n(String k) => int.tryParse(_gineco[k]!.text.trim());
    final g = GinecoObstetricos(
      gestas: n('gestas'),
      partos: n('partos'),
      cesareas: n('cesareas'),
      abortos: n('abortos'),
      perdidasFetales: n('perdidasFetales'),
      menarquia: t('menarquia'),
      ultimaMenstruacion: t('ultimaMenstruacion'),
      trastornosMenstruales: t('trastornosMenstruales'),
      eclampsia: t('eclampsia'),
      menopausia: t('menopausia'),
      metodoAnticonceptivo: t('metodoAnticonceptivo'),
    );
    return g.aJson().isEmpty ? null : g;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final antecedentes = Antecedentes(
      grupoSanguineo: _grupo,
      datosSociales: _pares(_identificacion),
      personales: _personales,
      familiares: _familiares,
      habitos: _pares(_habitos),
      medicamentosActuales: _medicamentos,
      ginecoObstetricos: _leerGineco(),
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

  /// Un antecedente plegable: muestra cuántos elementos tiene y, al abrirlo, el editor.
  Widget _plegable({int? numero, required CampoHistoria campo, required List<String> valores, required ValueChanged<List<String>> alCambiar}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: numero == null
              ? null
              : CircleAvatar(radius: 12, backgroundColor: valores.isEmpty ? AppColors.borde : AppColors.primario,
                  child: Text('$numero', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: valores.isEmpty ? AppColors.pizarra : Colors.white))),
          title: Text(campo.etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          subtitle: Text(valores.isEmpty ? 'Niega / no registrado' : valores.join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.pizarra)),
          children: [
            EditorLista(etiqueta: 'Agregar ${campo.etiqueta.toLowerCase()}', ayuda: campo.guia, valores: valores, sugerencias: campo.sugerencias, alCambiar: alCambiar),
          ],
        ),
      ),
    );
  }

  Widget _campos(Map<String, TextEditingController> controles, List<CampoHistoria> catalogo, {double minAncho = 240}) =>
      RejillaAdaptable(minAncho: minAncho, espacio: 12, children: [
        for (final c in catalogo) TextField(controller: controles[c.clave], decoration: AppTheme.campo(c.etiqueta)),
      ]);

  Widget _bloque(String numeral, String titulo, List<Widget> hijos, {String? subtitulo}) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SeccionDocumento(
          numeral: numeral,
          titulo: titulo,
          subtitulo: subtitulo,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < hijos.length; i++) ...[if (i > 0) const SizedBox(height: 12), hijos[i]],
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ginecoCampos = [
      for (final (k, e) in const [('gestas', 'Embarazos'), ('partos', 'Partos'), ('cesareas', 'Cesáreas'), ('abortos', 'Abortos'), ('perdidasFetales', 'Pérdidas fetales')])
        SizedBox(width: 130, child: TextField(controller: _gineco[k], keyboardType: TextInputType.number, decoration: AppTheme.campo(e))),
    ];
    const ginecoTextos = [
      ('menarquia', 'Menarquia (edad)'),
      ('ultimaMenstruacion', 'Fecha de última menstruación (FUM)'),
      ('trastornosMenstruales', 'Trastornos menstruales'),
      ('eclampsia', 'Eclampsia'),
      ('menopausia', 'Menopausia'),
      ('metodoAnticonceptivo', 'Método anticonceptivo'),
    ];

    final personales = <Widget>[
      for (final (n, c) in antecedentesPersonales) ...[
        if (n == 11 && widget.femenino)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.ambarSuave.withAlpha(120), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                CircleAvatar(radius: 12, backgroundColor: AppColors.ambar, child: Text('10', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white))),
                SizedBox(width: 12),
                Text('Ginecobstétricos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: ginecoCampos),
              const SizedBox(height: 10),
              RejillaAdaptable(minAncho: 240, espacio: 10, children: [
                for (final (k, e) in ginecoTextos) TextField(controller: _gineco[k], decoration: AppTheme.campo(e)),
              ]),
            ]),
          ),
        _plegable(numero: n, campo: c, valores: _personales[c.clave]!, alCambiar: (v) => setState(() => _personales[c.clave] = v)),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identificación y antecedentes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'Guardando…' : 'Guardar')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 880,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.autoReportado ? 'Estos datos los reportas tú y los ven los médicos que autorices. ' : ''}'
                'Abre cada antecedente para agregarlo: toca una sugerencia del modelo o escribe y pulsa Enter. Lo que quede vacío se registra como "niega".',
                style: const TextStyle(color: AppColors.pizarra, height: 1.45),
              ),
            ),
            _bloque('ID', 'Identificación', [
              const Text('Grupo sanguíneo', style: TextStyle(fontWeight: FontWeight.w600)),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ChoiceChip(label: const Text('No sé'), selected: _grupo == null, onSelected: (_) => setState(() => _grupo = null)),
                for (final g in gruposSanguineos) ChoiceChip(label: Text(g), selected: _grupo == g, onSelected: (_) => setState(() => _grupo = g)),
              ]),
              _campos(_identificacion, camposIdentificacion),
            ], subtitulo: 'Nombres, apellidos, sexo, fecha de nacimiento y C.I. vienen del perfil'),
            _bloque('III', 'Antecedentes personales', personales),
            _bloque('IV', 'Antecedentes familiares', [
              for (final c in antecedentesFamiliares)
                _plegable(campo: c, valores: _familiares[c.clave]!, alCambiar: (v) => setState(() => _familiares[c.clave] = v)),
            ], subtitulo: 'Indica el parentesco, p. ej. "Madre: HTA"'),
            _bloque('V', 'Historia personal y social', [
              _campos(_habitos, habitosCatalogo, minAncho: 200),
              _plegable(
                campo: const CampoHistoria('medicamentos', 'Medicamentos', guia: 'Nombre, dosis y frecuencia'),
                valores: _medicamentos,
                alCambiar: (v) => setState(() => _medicamentos = v),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
