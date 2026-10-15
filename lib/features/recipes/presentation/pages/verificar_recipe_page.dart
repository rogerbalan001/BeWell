import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/recipes_usecases.dart';
import 'recipe_widgets.dart';

/// Verificación pública de récipes para farmacias (no requiere sesión).
class VerificarRecipePage extends StatefulWidget {
  const VerificarRecipePage({super.key, this.codigo});
  final String? codigo;

  @override
  State<VerificarRecipePage> createState() => _VerificarRecipePageState();
}

class _VerificarRecipePageState extends State<VerificarRecipePage> {
  late final _codigo = TextEditingController(text: widget.codigo ?? '');
  VerificacionRecipe? _resultado;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if ((widget.codigo ?? '').isNotEmpty) _verificar();
  }

  Future<void> _verificar() async {
    if (_codigo.text.trim().isEmpty) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await sl<VerificarRecipe>()(_codigo.text);
      if (mounted) setState(() => _resultado = r);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const BwLogo(tamano: 30),
        actions: [TextButton(onPressed: () => context.go('/'), child: const Text('Ir a Bewell'))],
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 680,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Encabezado(
              antetitulo: 'Farmacias',
              titulo: 'Verificar récipe digital',
              descripcion: 'Ingresa el código impreso en el récipe o escanea su QR para confirmar emisor, vigencia e integridad.',
            ),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _codigo,
                  textCapitalization: TextCapitalization.characters,
                  decoration: AppTheme.campo('Código (RX-XXXXX-XXXXX)', icono: Icons.qr_code),
                  onSubmitted: (_) => _verificar(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _cargando ? null : _verificar, child: const Text('Verificar')),
            ]),
            const SizedBox(height: 20),
            if (_cargando) const VistaCargando(),
            if (_error != null) VistaError(_error!),
            if (r != null && !_cargando) _Resultado(r),
          ]),
        ),
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado(this.r);
  final VerificacionRecipe r;

  @override
  Widget build(BuildContext context) {
    if (!r.encontrado) {
      return const BwTarjeta(
        color: AppColors.errorSuave,
        child: Row(children: [
          Icon(Icons.gpp_bad_outlined, color: AppColors.error, size: 36),
          SizedBox(width: 12),
          Expanded(child: Text('No existe un récipe con ese código. No lo despache.', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
    }
    final color = r.valido ? AppColors.verdeOscuro : AppColors.error;
    final motivo = !r.firmaValida || !r.integro
        ? 'La firma digital no coincide: el contenido pudo ser alterado.'
        : r.estado == 'ANULADO'
            ? 'El médico anuló este récipe${r.motivoAnulacion != null ? ': ${r.motivoAnulacion}' : ''}.'
            : 'El récipe está vencido.';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      BwTarjeta(
        color: r.valido ? AppColors.verdeSuave : AppColors.errorSuave,
        child: Row(children: [
          Icon(r.valido ? Icons.verified_rounded : Icons.gpp_bad_outlined, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.valido ? 'Récipe válido' : 'Récipe NO válido', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
              Text(r.valido ? 'Firma digital verificada y contenido íntegro.' : motivo),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      BwTarjeta(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FilaDato('Código', r.codigo ?? ''),
          FilaDato('Médico', '${r.medicoNombre ?? ''}${r.medicoVerificado ? ' ✓' : ''}'),
          FilaDato('Especialidad', r.especialidad ?? ''),
          if (r.colegiatura != null) FilaDato('Colegiatura', r.colegiatura!),
          FilaDato('Paciente', '${r.pacienteNombre ?? ''}${r.pacienteCedula != null ? ' · ${r.pacienteCedula}' : ''}'),
          if (r.emitidoEn != null) FilaDato('Emitido', Formatos.fechaHora(r.emitidoEn!)),
          if (r.validoHasta != null) FilaDato('Válido hasta', Formatos.fechaCorta(r.validoHasta!)),
          const Divider(height: 24),
          ListaItemsRecipe(r.items),
          const SizedBox(height: 8),
          Text('Algoritmo ${r.algoritmo ?? ''} · hash ${r.hash ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.pizarraClara)),
        ]),
      ),
    ]);
  }
}
