import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/ficha_emergencia.dart';
import '../../domain/usecases/emergencia_usecases.dart';

/// HU: ficha médica de emergencia con código QR (por perfil familiar).
class FichaEmergenciaPage extends StatelessWidget {
  const FichaEmergenciaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final p = s.seleccionado;
        if (p == null) return const VistaCargando();
        return _Editor(key: ValueKey(p.id), pacienteId: p.id, nombre: p.nombreCompleto);
      },
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.pacienteId, required this.nombre});
  final String pacienteId;
  final String nombre;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final _gestion = sl<GestionarFichaEmergencia>();
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  String? _grupo;
  final _alergias = TextEditingController();
  final _condiciones = TextEditingController();
  final _medicacion = TextEditingController();
  List<ContactoEmergencia> _contactos = [];
  Set<String> _publicos = {};
  bool _tieneQr = false;
  String? _urlQr;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final f = await _gestion.obtener(widget.pacienteId);
      final url = await _gestion.urlQr(widget.pacienteId);
      if (!mounted) return;
      setState(() {
        _grupo = f.grupoSanguineo;
        _alergias.text = f.alergias.join('\n');
        _condiciones.text = f.condicionesCronicas.join('\n');
        _medicacion.text = f.medicacionActual.join('\n');
        _contactos = [...f.contactos];
        _publicos = f.camposPublicos.toSet();
        _tieneQr = f.tieneQr;
        _urlQr = f.tieneQr ? url : null;
        _cargando = false;
      });
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    }
  }

  List<String> _lineas(TextEditingController c) => c.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final error = await intentar(() => _gestion.guardar(
          widget.pacienteId,
          FichaEmergencia(
            grupoSanguineo: _grupo,
            alergias: _lineas(_alergias),
            condicionesCronicas: _lineas(_condiciones),
            medicacionActual: _lineas(_medicacion),
            contactos: _contactos,
            camposPublicos: _publicos.toList(),
          ),
        ));
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarMensaje(context, error ?? 'Ficha actualizada. El QR muestra la información nueva de inmediato.', error: error != null);
  }

  Future<void> _regenerar() async {
    if (_tieneQr) {
      final ok = await confirmar(context,
          titulo: 'Regenerar código QR', mensaje: 'El QR anterior dejará de funcionar de inmediato (por ejemplo, si perdiste tu tarjeta impresa).', accion: 'Regenerar');
      if (!ok) return;
    }
    try {
      final url = await _gestion.regenerarQr(widget.pacienteId);
      if (mounted) {
        setState(() {
          _urlQr = url;
          _tieneQr = true;
        });
      }
    } on Failure catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  Future<void> _agregarContacto() async {
    final nombre = TextEditingController();
    final parentesco = TextEditingController();
    final telefono = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contacto de emergencia'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nombre, decoration: AppTheme.campo('Nombre')),
            const SizedBox(height: 8),
            TextField(controller: parentesco, decoration: AppTheme.campo('Parentesco')),
            const SizedBox(height: 8),
            TextField(controller: telefono, keyboardType: TextInputType.phone, decoration: AppTheme.campo('Teléfono')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true && nombre.text.trim().isNotEmpty && telefono.text.trim().isNotEmpty) {
      setState(() => _contactos = [
            ..._contactos,
            ContactoEmergencia(nombre: nombre.text.trim(), parentesco: parentesco.text.trim(), telefono: telefono.text.trim()),
          ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const VistaCargando();
    if (_error != null) return VistaError(_error!, reintentar: _cargar);
    final ancho = MediaQuery.sizeOf(context).width;

    final formulario = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SeccionTarjeta(
        titulo: 'Datos críticos',
        icono: Icons.bloodtype_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Grupo sanguíneo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final g in gruposSanguineos) ChoiceChip(label: Text(g), selected: _grupo == g, onSelected: (_) => setState(() => _grupo = g)),
          ]),
          const SizedBox(height: 14),
          TextField(controller: _alergias, maxLines: 3, decoration: AppTheme.campo('Alergias (una por línea)', icono: Icons.warning_amber_rounded)),
          const SizedBox(height: 10),
          TextField(controller: _condiciones, maxLines: 3, decoration: AppTheme.campo('Condiciones críticas (una por línea)', icono: Icons.monitor_heart_outlined)),
          const SizedBox(height: 10),
          TextField(controller: _medicacion, maxLines: 3, decoration: AppTheme.campo('Medicación actual (una por línea)', icono: Icons.medication_outlined)),
        ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: 'Contactos de emergencia',
        icono: Icons.contact_phone_outlined,
        accion: IconButton(onPressed: _agregarContacto, icon: const Icon(Icons.add)),
        child: _contactos.isEmpty
            ? const Text('Agrega al menos un contacto.', style: TextStyle(color: AppColors.pizarra))
            : Column(children: [
                for (final c in _contactos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(c.nombre),
                    subtitle: Text('${c.parentesco} · ${c.telefono}'),
                    trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _contactos = [..._contactos]..remove(c))),
                  ),
              ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: 'Qué se muestra sin iniciar sesión',
        subtitulo: 'El personal de emergencia verificado ve la ficha completa. El QR nunca muestra el resto del expediente.',
        icono: Icons.visibility_outlined,
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final e in camposFicha.entries)
            FilterChip(
              label: Text(e.value),
              selected: _publicos.contains(e.key),
              onSelected: (s) => setState(() => s ? _publicos.add(e.key) : _publicos.remove(e.key)),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _guardando ? null : _guardar, icon: const Icon(Icons.save_outlined), label: const Text('Guardar ficha')),
    ]);

    final qr = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        const Text('PASE MÉDICO DE EMERGENCIA', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(widget.nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        if (_grupo != null) Text('Grupo $_grupo', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        if (_urlQr != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: QrImageView(data: _urlQr!, version: QrVersions.auto, size: 210),
          )
        else
          Container(
            height: 210,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
            child: Text(
              _tieneQr
                  ? 'Este dispositivo no tiene el QR vigente (por seguridad el servidor no lo guarda). Regenéralo para verlo aquí.'
                  : 'Aún no has generado tu código QR.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.marino),
          onPressed: _regenerar,
          icon: const Icon(Icons.qr_code_2),
          label: Text(_tieneQr ? 'Regenerar QR' : 'Generar QR'),
        ),
        if (_urlQr != null) ...[
          const SizedBox(height: 10),
          SelectableText(_urlQr!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        const Text('Cada escaneo queda registrado y te notificamos.', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );

    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Encabezado(
            antetitulo: 'Acceso de emergencia QR',
            titulo: 'Ficha médica de emergencia',
            descripcion: 'Para ${widget.nombre}. Permite a paramédicos ver tu tipo de sangre, alergias y contactos aunque no puedas hablar.',
          ),
          if (ancho >= 980)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: formulario),
              const SizedBox(width: 24),
              SizedBox(width: 340, child: qr),
            ])
          else ...[
            qr,
            const SizedBox(height: 16),
            formulario,
          ],
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _alergias.dispose();
    _condiciones.dispose();
    _medicacion.dispose();
    super.dispose();
  }
}
