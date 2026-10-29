import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/catalogo_historia.dart';
import '../../domain/entities/historia_clinica.dart';

const _etiquetaEstilo = TextStyle(color: AppColors.pizarraClara, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8);

/// Rejilla que reparte sus hijos en tantas columnas como quepan (mínimo [minAncho] cada una).
class RejillaAdaptable extends StatelessWidget {
  const RejillaAdaptable({super.key, required this.children, this.minAncho = 260, this.espacio = 14});
  final List<Widget> children;
  final double minAncho;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final columnas = (c.maxWidth / minAncho).floor().clamp(1, 4);
      final ancho = (c.maxWidth - espacio * (columnas - 1)) / columnas;
      return Wrap(spacing: espacio, runSpacing: espacio, children: [
        for (final h in children) SizedBox(width: ancho, child: h),
      ]);
    });
  }
}

/// Insignia con el numeral romano de una sección del modelo (III, VII…).
class NumeralSeccion extends StatelessWidget {
  const NumeralSeccion(this.numeral, {super.key, this.tamano = 36});
  final String numeral;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(tamano * 0.3)),
      child: Text(numeral,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: numeral.length > 3 ? tamano * 0.28 : tamano * 0.36)),
    );
  }
}

/// Sección de la historia con su numeral, como en el documento impreso.
class SeccionDocumento extends StatelessWidget {
  const SeccionDocumento({super.key, required this.numeral, required this.titulo, this.subtitulo, this.accion, required this.child});
  final String numeral;
  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BwTarjeta(
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          NumeralSeccion(numeral),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.marino)),
              if (subtitulo != null) Text(subtitulo!, style: const TextStyle(color: AppColors.pizarraClara, fontSize: 12.5)),
            ]),
          ),
          if (accion != null) accion!,
        ]),
        const SizedBox(height: 18),
        child,
      ]),
    );
  }
}

/// Dato con etiqueta arriba y valor abajo (encabezado de identificación, hábitos…).
class CampoDato extends StatelessWidget {
  const CampoDato(this.etiqueta, this.valor, {super.key});
  final String etiqueta;
  final String? valor;

  @override
  Widget build(BuildContext context) {
    final vacio = valor == null || valor!.trim().isEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(etiqueta.toUpperCase(), style: _etiquetaEstilo),
      const SizedBox(height: 3),
      Text(vacio ? '—' : valor!,
          style: TextStyle(fontSize: 14, height: 1.35, color: vacio ? AppColors.pizarraClara : AppColors.marino, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// Un antecedente numerado: título y sus elementos como etiquetas, o "Niega".
class ItemAntecedente extends StatelessWidget {
  const ItemAntecedente({super.key, this.numero, required this.titulo, required this.valores, this.color = AppColors.primario, this.extra});
  final int? numero;
  final String titulo;
  final List<String> valores;
  final Color color;

  /// Contenido adicional bajo las etiquetas (p. ej. la fórmula obstétrica).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final vacio = valores.isEmpty && extra == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vacio ? AppColors.lienzo : AppColors.superficieAzul,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vacio ? AppColors.borde : color.withAlpha(40)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (numero != null) ...[
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: vacio ? AppColors.borde : color, shape: BoxShape.circle),
              child: Text('$numero', style: TextStyle(color: vacio ? AppColors.pizarra : Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(titulo,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: vacio ? AppColors.pizarra : AppColors.marino)),
          ),
        ]),
        const SizedBox(height: 8),
        if (vacio)
          const Text('Niega / no registrado', style: TextStyle(color: AppColors.pizarraClara, fontSize: 13))
        else ...[
          if (valores.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final v in valores)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.superficie, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withAlpha(50))),
                  child: Text(v, style: const TextStyle(fontSize: 13, color: AppColors.marino, height: 1.3)),
                ),
            ]),
          if (extra != null) ...[if (valores.isNotEmpty) const SizedBox(height: 8), extra!],
        ],
      ]),
    );
  }
}

/// Recuadro de un signo vital.
class TileSigno extends StatelessWidget {
  const TileSigno(this.etiqueta, this.valor, this.unidad, {super.key});
  final String etiqueta;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.verdeSuave.withAlpha(110), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta.toUpperCase(), style: const TextStyle(color: AppColors.verdeOscuro, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text.rich(TextSpan(children: [
          TextSpan(text: valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.marino)),
          TextSpan(text: ' $unidad', style: const TextStyle(fontSize: 12, color: AppColors.pizarra)),
        ])),
      ]),
    );
  }
}

/// Bloque de una consulta con su numeral pequeño.
class _BloqueConsulta extends StatelessWidget {
  const _BloqueConsulta(this.numeral, this.titulo, this.child);
  final String numeral;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumeralSeccion(numeral, tamano: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 8),
              child: Text(titulo.toUpperCase(), style: const TextStyle(color: AppColors.primario, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            child,
          ]),
        ),
      ]),
    );
  }
}

const _texto = TextStyle(fontSize: 14, height: 1.5, color: AppColors.marino);
const _tenue = TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.pizarraClara);

/// Hallazgos por sistema o región: solo los que tienen dato y, debajo, los que no.
class _Hallazgos extends StatelessWidget {
  const _Hallazgos({required this.catalogo, required this.valores, required this.textoSinDato});
  final List<CampoHistoria> catalogo;
  final Map<String, String> valores;
  final String textoSinDato;

  @override
  Widget build(BuildContext context) {
    final con = [for (final c in catalogo) if ((valores[c.clave] ?? '').isNotEmpty) c];
    final sin = [for (final c in catalogo) if ((valores[c.clave] ?? '').isEmpty) c.etiqueta];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (con.isNotEmpty)
        RejillaAdaptable(minAncho: 280, espacio: 10, children: [
          for (final c in con)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primarioOscuro)),
                const SizedBox(height: 3),
                Text(valores[c.clave]!, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.marino)),
              ]),
            ),
        ]),
      if (sin.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('$textoSinDato: ${sin.join(', ')}.', style: _tenue),
      ],
    ]);
  }
}

/// Tarjeta expandible con la historia completa de una consulta.
class TarjetaConsulta extends StatelessWidget {
  const TarjetaConsulta({super.key, required this.consulta, this.alCorregir, this.inicialmenteAbierta = false});
  final ConsultaClinica consulta;
  final VoidCallback? alCorregir;
  final bool inicialmenteAbierta;

  @override
  Widget build(BuildContext context) {
    final c = consulta.contenido;
    final medico = consulta.medico;
    final f = consulta.fecha;
    Widget? parrafo(String? texto) => (texto == null || texto.trim().isEmpty) ? null : Text(texto, style: _texto);
    Widget pares(List<(String, String?)> filas) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (etiqueta, valor) in filas)
            if (valor != null && valor.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '$etiqueta: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: valor),
                ]), style: _texto),
              ),
        ]);
    Widget numerada(List<String> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${i + 1}. ${items[i]}', style: _texto),
            ),
        ]);
    final examenes = [for (final t in tiposExamenes) (t.etiqueta, c.examenes[t.clave])];
    final planes = [
      ('Diagnóstico', c.planDiagnostico),
      ('Preventivo', c.planPreventivo),
      ('Educativo', c.indicaciones),
      ('Terapéutico', c.plan),
    ];

    return BwTarjeta(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: inicialmenteAbierta,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${f.day}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primarioOscuro, height: 1.1)),
              Text(Formatos.mesAnio(f).substring(0, 3).toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primario, letterSpacing: 0.6)),
              Text('${f.year}', style: const TextStyle(fontSize: 10, color: AppColors.pizarraClara)),
            ]),
          ),
          title: Text(c.motivoConsulta, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.marino)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (medico != null) Text('${medico.nombreCompleto} · ${medico.especialidad}', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final d in c.impresionDiagnostica) ChipEstado(d, color: AppColors.marino, fondo: AppColors.superficieAzul2, icono: Icons.local_hospital_outlined),
              ]),
            ]),
          ),
          children: [
            const Divider(height: 1),
            _BloqueConsulta('I', 'Motivo de consulta', pares([('Motivo', c.motivoConsulta), ('Estímulo iatrotrópico', c.estimuloIatrotropico)])),
            _BloqueConsulta('II', 'Enfermedad actual', parrafo(c.enfermedadActual)!),
            _BloqueConsulta(
              'VI',
              'Revisión por aparatos y sistemas',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Hallazgos(catalogo: sistemasRevision, valores: c.revisionSistemas, textoSinDato: 'Sin síntomas referidos'),
                if (parrafo(c.revisionPorSistemas) != null) ...[const SizedBox(height: 8), parrafo(c.revisionPorSistemas)!],
              ]),
            ),
            _BloqueConsulta(
              'VII',
              'Examen físico',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (parrafo(c.condicionesGenerales) != null) ...[
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Condiciones generales: ', style: TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: c.condicionesGenerales),
                  ]), style: _texto),
                  const SizedBox(height: 12),
                ],
                if (!c.signosVitales.vacio) ...[
                  RejillaAdaptable(minAncho: 130, espacio: 8, children: [
                    for (final (e, v, u) in c.signosVitales.mediciones) TileSigno(e, v, u),
                  ]),
                  const SizedBox(height: 14),
                ],
                _Hallazgos(catalogo: regionesExamen, valores: c.examenRegiones, textoSinDato: 'No explorado o sin alteraciones'),
                if (parrafo(c.examenFisico) != null) ...[const SizedBox(height: 8), parrafo(c.examenFisico)!],
              ]),
            ),
            if (parrafo(c.resumenDatosPositivos) != null) _BloqueConsulta('VIII', 'Resumen de datos positivos', parrafo(c.resumenDatosPositivos)!),
            _BloqueConsulta(
              'IX',
              'Lista de problemas',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (c.listaProblemas.isEmpty) const Text('Sin problemas registrados.', style: _tenue) else numerada(c.listaProblemas),
                const SizedBox(height: 6),
                c.consentimientoInformado
                    ? const ChipEstado('Consentimiento informado obtenido', icono: Icons.verified_outlined, color: AppColors.verdeOscuro)
                    : const ChipEstado('Consentimiento informado no registrado', icono: Icons.info_outline, color: AppColors.pizarra),
              ]),
            ),
            _BloqueConsulta('X', 'Impresión diagnóstica', numerada(c.impresionDiagnostica)),
            if (examenes.any((e) => (e.$2 ?? '').isNotEmpty)) _BloqueConsulta('XI', 'Exámenes', pares(examenes)),
            _BloqueConsulta('XII', 'Plan', pares(planes)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lienzo, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.draw_outlined, size: 18, color: AppColors.pizarra),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Elaborada por ${medico?.nombreCompleto ?? 'el médico tratante'} · ${Formatos.fechaCorta(consulta.creadaEn ?? f)}',
                    style: const TextStyle(color: AppColors.pizarra, fontSize: 13),
                  ),
                ),
                if (alCorregir != null)
                  OutlinedButton.icon(onPressed: alCorregir, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Corregir (24 h)')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editor de una lista de textos: chips eliminables, campo para agregar y
/// sugerencias del modelo que se agregan con un toque.
class EditorLista extends StatefulWidget {
  const EditorLista({super.key, required this.etiqueta, required this.valores, required this.alCambiar, this.ayuda, this.sugerencias = const []});
  final String etiqueta;
  final List<String> valores;
  final ValueChanged<List<String>> alCambiar;
  final String? ayuda;
  final List<String> sugerencias;

  @override
  State<EditorLista> createState() => _EditorListaState();
}

class _EditorListaState extends State<EditorLista> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _agregar([String? valor]) {
    final texto = (valor ?? _controlador.text).trim();
    if (texto.isEmpty) return;
    if (!widget.valores.contains(texto)) widget.alCambiar([...widget.valores, texto]);
    if (valor == null) _controlador.clear();
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = [for (final s in widget.sugerencias) if (!widget.valores.contains(s)) s];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _controlador,
        onSubmitted: (_) => _agregar(),
        decoration: AppTheme.campo(widget.etiqueta, ayuda: widget.ayuda).copyWith(
          suffixIcon: IconButton(tooltip: 'Agregar', icon: const Icon(Icons.add_circle_outline), onPressed: _agregar),
        ),
      ),
      if (widget.valores.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in widget.valores)
            InputChip(label: Text(v), onDeleted: () => widget.alCambiar(widget.valores.where((x) => x != v).toList())),
        ]),
      ],
      if (pendientes.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in pendientes)
            ActionChip(
              avatar: const Icon(Icons.add, size: 16, color: AppColors.primario),
              label: Text(s, style: const TextStyle(fontSize: 12.5, color: AppColors.primarioOscuro)),
              backgroundColor: AppColors.superficie,
              side: const BorderSide(color: AppColors.bordeAzul),
              visualDensity: VisualDensity.compact,
              onPressed: () => _agregar(s),
            ),
        ]),
      ],
    ]);
  }
}
