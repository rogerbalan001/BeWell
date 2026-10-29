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

/// Médico: registra la historia de una consulta (o la corrige si [existente]
/// no es nulo) con las secciones I, II y VI a XII del modelo integral. Con
/// [citaId] queda vinculada a esa cita. Devuelve true al guardar.
class ConsultaFormPage extends StatefulWidget {
  const ConsultaFormPage({super.key, required this.pacienteId, this.pacienteNombre, this.citaId, this.existente});
  final String pacienteId;
  final String? pacienteNombre;
  final String? citaId;
  final ConsultaClinica? existente;

  @override
  State<ConsultaFormPage> createState() => _ConsultaFormPageState();
}

TextEditingController _ctl(String? v) => TextEditingController(text: v ?? '');
String _txt(double? v) => v == null ? '' : SignosVitales.n(v);

class _ConsultaFormPageState extends State<ConsultaFormPage> {
  final _form = GlobalKey<FormState>();
  late final ContenidoConsulta? _c = widget.existente?.contenido;

  late final _motivo = _ctl(_c?.motivoConsulta);
  late final _estimulo = _ctl(_c?.estimuloIatrotropico);
  late final _enfermedad = _ctl(_c?.enfermedadActual);
  late final _revisionGeneral = _ctl(_c?.revisionPorSistemas);
  late final _condiciones = _ctl(_c?.condicionesGenerales);
  late final _examenGeneral = _ctl(_c?.examenFisico);
  late final _resumen = _ctl(_c?.resumenDatosPositivos);
  late final _planDiagnostico = _ctl(_c?.planDiagnostico);
  late final _planPreventivo = _ctl(_c?.planPreventivo);
  late final _planEducativo = _ctl(_c?.indicaciones);
  late final _planTerapeutico = _ctl(_c?.plan);
  late final Map<String, TextEditingController> _sistemas = {for (final s in sistemasRevision) s.clave: _ctl(_c?.revisionSistemas[s.clave])};
  late final Map<String, TextEditingController> _regiones = {for (final r in regionesExamen) r.clave: _ctl(_c?.examenRegiones[r.clave])};
  late final Map<String, TextEditingController> _examenes = {for (final t in tiposExamenes) t.clave: _ctl(_c?.examenes[t.clave])};
  late List<String> _problemas = _c?.listaProblemas ?? const [];
  late List<String> _diagnosticos = _c?.impresionDiagnostica ?? const [];
  late bool _consentimiento = _c?.consentimientoInformado ?? false;

  late final SignosVitales _sv = _c?.signosVitales ?? const SignosVitales();
  late final _taAcostado = _ctl(_sv.tensionArterialAcostado);
  late final _taSentado = _ctl(_sv.tensionArterial);
  late final _taDePie = _ctl(_sv.tensionArterialDePie);
  late final _fc = _ctl(_txt(_sv.frecuenciaCardiaca));
  late final _fr = _ctl(_txt(_sv.frecuenciaRespiratoria));
  late final _temp = _ctl(_txt(_sv.temperatura));
  late final _sat = _ctl(_txt(_sv.saturacionOxigeno));
  late final _peso = _ctl(_txt(_sv.peso));
  late final _talla = _ctl(_txt(_sv.talla));
  late final _cintura = _ctl(_txt(_sv.circunferenciaAbdominal));

  bool _guardando = false;

  List<TextEditingController> get _todos => [
        _motivo, _estimulo, _enfermedad, _revisionGeneral, _condiciones, _examenGeneral, _resumen,
        _planDiagnostico, _planPreventivo, _planEducativo, _planTerapeutico,
        _taAcostado, _taSentado, _taDePie, _fc, _fr, _temp, _sat, _peso, _talla, _cintura,
        ..._sistemas.values, ..._regiones.values, ..._examenes.values,
      ];

  @override
  void initState() {
    super.initState();
    // El IMC se recalcula mientras se escriben peso y talla.
    _peso.addListener(_refrescar);
    _talla.addListener(_refrescar);
  }

  void _refrescar() => setState(() {});

  @override
  void dispose() {
    for (final c in _todos) {
      c.dispose();
    }
    super.dispose();
  }

  double? _numero(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));
  String? _pa(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.replaceAll(' ', '');

  SignosVitales get _signos => SignosVitales(
        tensionArterialAcostado: _pa(_taAcostado),
        tensionArterial: _pa(_taSentado),
        tensionArterialDePie: _pa(_taDePie),
        frecuenciaCardiaca: _numero(_fc),
        frecuenciaRespiratoria: _numero(_fr),
        temperatura: _numero(_temp),
        saturacionOxigeno: _numero(_sat),
        peso: _numero(_peso),
        talla: _numero(_talla),
        circunferenciaAbdominal: _numero(_cintura),
      );

  Map<String, String> _pares(Map<String, TextEditingController> m) => {
        for (final e in m.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _rango(String? v, double min, double max) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null) return 'Número inválido';
    if (n < min || n > max) return 'Entre ${min.toStringAsFixed(0)} y ${max.toStringAsFixed(0)}';
    return null;
  }

  String? _validarTa(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(v.replaceAll(' ', '')) ? null : 'Formato 120/80';
  }

  Future<void> _guardar() async {
    if (!(_form.currentState?.validate() ?? false)) {
      mostrarMensaje(context, 'Revisa los campos marcados en rojo', error: true);
      return;
    }
    if (_diagnosticos.isEmpty) {
      mostrarMensaje(context, 'Agrega al menos una impresión diagnóstica (X)', error: true);
      return;
    }
    if ([_planDiagnostico, _planPreventivo, _planEducativo, _planTerapeutico].every((c) => c.text.trim().isEmpty)) {
      mostrarMensaje(context, 'Completa al menos una parte del plan (XII)', error: true);
      return;
    }
    setState(() => _guardando = true);
    final contenido = ContenidoConsulta(
      motivoConsulta: _motivo.text.trim(),
      estimuloIatrotropico: _estimulo.text.trim(),
      enfermedadActual: _enfermedad.text.trim(),
      revisionSistemas: _pares(_sistemas),
      revisionPorSistemas: _revisionGeneral.text.trim(),
      condicionesGenerales: _condiciones.text.trim(),
      signosVitales: _signos,
      examenRegiones: _pares(_regiones),
      examenFisico: _examenGeneral.text.trim(),
      resumenDatosPositivos: _resumen.text.trim(),
      listaProblemas: _problemas,
      consentimientoInformado: _consentimiento,
      impresionDiagnostica: _diagnosticos,
      examenes: _pares(_examenes),
      planDiagnostico: _planDiagnostico.text.trim(),
      planPreventivo: _planPreventivo.text.trim(),
      plan: _planTerapeutico.text.trim(),
      indicaciones: _planEducativo.text.trim(),
    );
    final casoDeUso = sl<RegistrarConsultaClinica>();
    final existente = widget.existente;
    final error = await intentar(() async {
      if (existente != null) {
        await casoDeUso.corregir(widget.pacienteId, existente.id, contenido);
      } else {
        await casoDeUso(widget.pacienteId, contenido, citaId: widget.citaId);
      }
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, existente != null ? 'Historia corregida' : 'Historia de la consulta registrada');
    Navigator.of(context).pop(true);
  }

  Widget _campo(TextEditingController c, String etiqueta, {int lineas = 1, String? Function(String?)? validar, String? ayuda}) => TextFormField(
        controller: c,
        minLines: lineas,
        maxLines: lineas == 1 ? 1 : lineas + 4,
        validator: validar,
        decoration: AppTheme.campo(etiqueta, ayuda: ayuda),
      );

  /// Sistemas o regiones plegables: cada uno muestra la guía del modelo como ayuda.
  Widget _porSistema(List<CampoHistoria> catalogo, Map<String, TextEditingController> controles) {
    return Column(children: [
      for (final s in catalogo)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 14),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              leading: Icon(
                controles[s.clave]!.text.trim().isEmpty ? Icons.radio_button_unchecked : Icons.check_circle,
                size: 18,
                color: controles[s.clave]!.text.trim().isEmpty ? AppColors.pizarraClara : AppColors.verdeOscuro,
              ),
              title: Text(s.etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(
                controles[s.clave]!.text.trim().isEmpty ? (s.guia ?? 'Sin hallazgos') : controles[s.clave]!.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.pizarra),
              ),
              onExpansionChanged: (_) => setState(() {}),
              children: [
                TextFormField(
                  controller: controles[s.clave],
                  minLines: 2,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  decoration: AppTheme.campo('Hallazgos en ${s.etiqueta.toLowerCase()}', ayuda: s.guia),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

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
    final imc = _signos.imc;
    Widget vital(TextEditingController c, String etiqueta, String unidad, double min, double max) => TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => _rango(v, min, max),
          decoration: AppTheme.campo(etiqueta, sufijo: unidad),
        );
    Widget presion(TextEditingController c, String etiqueta) =>
        TextFormField(controller: c, validator: _validarTa, decoration: AppTheme.campo(etiqueta, sufijo: 'mmHg', ayuda: '120/80'));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existente != null ? 'Corregir historia de consulta' : 'Historia de la consulta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'Guardando…' : 'Guardar')),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          child: ContenidoCentrado(
            maxAncho: 900,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.pacienteNombre != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    AvatarIniciales(widget.pacienteNombre!, radio: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.pacienteNombre!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                    if (widget.citaId != null) const ChipEstado('Vinculada a la cita', icono: Icons.event_available, color: AppColors.primario),
                  ]),
                ),
              _bloque('I', 'Motivo de consulta', [
                _campo(_motivo, 'Motivo de consulta *', validar: _requerido, ayuda: 'En palabras del paciente'),
                _campo(_estimulo, 'Estímulo iatrotrópico', ayuda: '¿Por qué consulta ahora?'),
              ]),
              _bloque('II', 'Enfermedad actual', [
                _campo(_enfermedad, 'Enfermedad actual *', lineas: 5, validar: _requerido,
                    ayuda: 'Relato de todos los síntomas en orden cronológico: comienzo, duración y tratamiento de cada uno'),
              ]),
              _bloque('VI', 'Revisión por aparatos y sistemas', [
                _porSistema(sistemasRevision, _sistemas),
                _campo(_revisionGeneral, 'Observaciones generales', lineas: 2),
              ], subtitulo: 'Abre cada sistema con síntomas; los demás quedan como "sin síntomas referidos"'),
              _bloque('VII', 'Examen físico', [
                _campo(_condiciones, 'Condiciones generales'),
                const Text('Signos vitales', style: TextStyle(fontWeight: FontWeight.w700)),
                RejillaAdaptable(minAncho: 170, espacio: 10, children: [
                  presion(_taAcostado, 'PA acostado'),
                  presion(_taSentado, 'PA sentado'),
                  presion(_taDePie, 'PA de pie'),
                  vital(_fc, 'Pulso', 'ppm', 20, 250),
                  vital(_fr, 'Frec. resp.', 'rpm', 4, 80),
                  vital(_temp, 'Temperatura', '°C', 30, 45),
                  vital(_sat, 'SpO₂', '%', 50, 100),
                  vital(_peso, 'Peso', 'kg', 0.3, 400),
                  vital(_talla, 'Talla', 'cm', 20, 250),
                  vital(_cintura, 'C. abdominal', 'cm', 30, 250),
                ]),
                if (imc != null)
                  Align(alignment: Alignment.centerLeft, child: ChipEstado('IMC ${SignosVitales.n(imc)} kg/m²', icono: Icons.straighten, color: AppColors.verdeOscuro)),
                const SizedBox(height: 4),
                const Text('Exploración por regiones', style: TextStyle(fontWeight: FontWeight.w700)),
                _porSistema(regionesExamen, _regiones),
                _campo(_examenGeneral, 'Observaciones generales del examen', lineas: 2),
              ]),
              _bloque('VIII', 'Resumen de datos positivos', [
                _campo(_resumen, 'Datos positivos de la anamnesis y el examen', lineas: 3),
              ]),
              _bloque('IX', 'Lista de problemas', [
                EditorLista(etiqueta: 'Agregar problema', valores: _problemas, alCambiar: (v) => setState(() => _problemas = v)),
                Container(
                  decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
                  child: SwitchListTile(
                    value: _consentimiento,
                    onChanged: (v) => setState(() => _consentimiento = v),
                    title: const Text('Consentimiento informado obtenido', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Aspectos éticos'),
                  ),
                ),
              ]),
              _bloque('X', 'Impresión diagnóstica', [
                EditorLista(
                  etiqueta: 'Agregar diagnóstico *',
                  ayuda: 'Uno o más diagnósticos; puedes incluir el código CIE-10',
                  valores: _diagnosticos,
                  alCambiar: (v) => setState(() => _diagnosticos = v),
                ),
              ]),
              _bloque('XI', 'Exámenes', [
                RejillaAdaptable(minAncho: 260, espacio: 12, children: [
                  for (final t in tiposExamenes) _campo(_examenes[t.clave]!, t.etiqueta, lineas: 2),
                ]),
              ]),
              _bloque('XII', 'Plan', [
                RejillaAdaptable(minAncho: 260, espacio: 12, children: [
                  _campo(_planDiagnostico, 'Diagnóstico', lineas: 2),
                  _campo(_planPreventivo, 'Preventivo', lineas: 2),
                  _campo(_planEducativo, 'Educativo', lineas: 2, ayuda: 'Indicaciones al paciente'),
                  _campo(_planTerapeutico, 'Terapéutico', lineas: 2, ayuda: 'Medicamentos, dosis y duración'),
                ]),
              ], subtitulo: 'Completa al menos una parte'),
              const Text(
                'La historia se puede corregir durante 24 horas; después queda fija. El paciente recibe una notificación.',
                style: TextStyle(color: AppColors.pizarraClara, fontSize: 12.5),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
