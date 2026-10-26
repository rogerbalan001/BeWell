import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';
import '../widgets/historia_widgets.dart';

/// Médico: registra la historia de una consulta (o la corrige si [existente]
/// no es nulo). Con [citaId] queda vinculada a esa cita. Devuelve true al guardar.
class ConsultaFormPage extends StatefulWidget {
  const ConsultaFormPage({super.key, required this.pacienteId, this.pacienteNombre, this.citaId, this.existente});
  final String pacienteId;
  final String? pacienteNombre;
  final String? citaId;
  final ConsultaClinica? existente;

  @override
  State<ConsultaFormPage> createState() => _ConsultaFormPageState();
}

class _ConsultaFormPageState extends State<ConsultaFormPage> {
  final _form = GlobalKey<FormState>();
  late final ContenidoConsulta? _c = widget.existente?.contenido;
  late final _motivo = TextEditingController(text: _c?.motivoConsulta ?? '');
  late final _enfermedad = TextEditingController(text: _c?.enfermedadActual ?? '');
  late final _sistemas = TextEditingController(text: _c?.revisionPorSistemas ?? '');
  late final _examen = TextEditingController(text: _c?.examenFisico ?? '');
  late final _plan = TextEditingController(text: _c?.plan ?? '');
  late final _indicaciones = TextEditingController(text: _c?.indicaciones ?? '');
  late List<String> _diagnosticos = _c?.impresionDiagnostica ?? const [];

  late final SignosVitales _sv = _c?.signosVitales ?? const SignosVitales();
  late final _ta = TextEditingController(text: _sv.tensionArterial ?? '');
  late final _fc = TextEditingController(text: _txt(_sv.frecuenciaCardiaca));
  late final _fr = TextEditingController(text: _txt(_sv.frecuenciaRespiratoria));
  late final _temp = TextEditingController(text: _txt(_sv.temperatura));
  late final _sat = TextEditingController(text: _txt(_sv.saturacionOxigeno));
  late final _peso = TextEditingController(text: _txt(_sv.peso));
  late final _talla = TextEditingController(text: _txt(_sv.talla));

  bool _guardando = false;

  static String _txt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  List<TextEditingController> get _todos => [_motivo, _enfermedad, _sistemas, _examen, _plan, _indicaciones, _ta, _fc, _fr, _temp, _sat, _peso, _talla];

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

  SignosVitales get _signos => SignosVitales(
        tensionArterial: _ta.text.trim().isEmpty ? null : _ta.text.replaceAll(' ', ''),
        frecuenciaCardiaca: _numero(_fc),
        frecuenciaRespiratoria: _numero(_fr),
        temperatura: _numero(_temp),
        saturacionOxigeno: _numero(_sat),
        peso: _numero(_peso),
        talla: _numero(_talla),
      );

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
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_diagnosticos.isEmpty) {
      mostrarMensaje(context, 'Agrega al menos una impresión diagnóstica', error: true);
      return;
    }
    setState(() => _guardando = true);
    final contenido = ContenidoConsulta(
      motivoConsulta: _motivo.text.trim(),
      enfermedadActual: _enfermedad.text.trim(),
      revisionPorSistemas: _sistemas.text.trim(),
      signosVitales: _signos,
      examenFisico: _examen.text.trim(),
      impresionDiagnostica: _diagnosticos,
      plan: _plan.text.trim(),
      indicaciones: _indicaciones.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final imc = _signos.imc;
    Widget campo(TextEditingController c, String etiqueta, {int lineas = 1, String? Function(String?)? validar, String? ayuda}) => TextFormField(
          controller: c,
          minLines: lineas,
          maxLines: lineas == 1 ? 1 : lineas + 4,
          validator: validar,
          decoration: AppTheme.campo(etiqueta, ayuda: ayuda),
        );
    Widget vital(TextEditingController c, String etiqueta, String unidad, double min, double max) => SizedBox(
          width: 150,
          child: TextFormField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => _rango(v, min, max),
            decoration: AppTheme.campo(etiqueta, sufijo: unidad),
          ),
        );
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
            maxAncho: 860,
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
              bloque('Anamnesis', Icons.record_voice_over_outlined, [
                campo(_motivo, 'Motivo de consulta *', validar: _requerido, ayuda: 'En palabras del paciente'),
                campo(_enfermedad, 'Enfermedad actual *', lineas: 4, validar: _requerido, ayuda: 'Inicio, evolución, síntomas asociados y tratamientos recibidos'),
                campo(_sistemas, 'Revisión por sistemas', lineas: 3),
              ]),
              bloque('Examen físico', Icons.monitor_heart_outlined, [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                    width: 150,
                    child: TextFormField(controller: _ta, validator: _validarTa, decoration: AppTheme.campo('TA', sufijo: 'mmHg', ayuda: '120/80')),
                  ),
                  vital(_fc, 'FC', 'lpm', 20, 250),
                  vital(_fr, 'FR', 'rpm', 4, 80),
                  vital(_temp, 'Temperatura', '°C', 30, 45),
                  vital(_sat, 'SpO₂', '%', 50, 100),
                  vital(_peso, 'Peso', 'kg', 0.3, 400),
                  vital(_talla, 'Talla', 'cm', 20, 250),
                ]),
                if (imc != null)
                  Align(alignment: Alignment.centerLeft, child: ChipEstado('IMC $imc kg/m²', icono: Icons.straighten, color: AppColors.verdeOscuro)),
                campo(_examen, 'Hallazgos del examen físico', lineas: 4, ayuda: 'Por aparatos y sistemas'),
              ]),
              bloque('Impresión diagnóstica y plan', Icons.local_hospital_outlined, [
                EditorLista(
                  etiqueta: 'Impresión diagnóstica *',
                  ayuda: 'Agrega uno o más diagnósticos (puedes incluir el código CIE-10)',
                  valores: _diagnosticos,
                  alCambiar: (v) => setState(() => _diagnosticos = v),
                ),
                campo(_plan, 'Plan *', lineas: 3, validar: _requerido, ayuda: 'Estudios, tratamiento y seguimiento'),
                campo(_indicaciones, 'Indicaciones al paciente', lineas: 3),
              ]),
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
