import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/usecases/perfiles_usecases.dart';
import '../cubit/perfil_activo_cubit.dart';

/// HU: gestionar los perfiles de mis hijos o padres desde mi cuenta.
class PerfilesPage extends StatelessWidget {
  const PerfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(builder: (context, s) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Mi familia',
              titulo: 'Perfiles familiares',
              descripcion: 'Centraliza la salud de toda tu familia. Cada perfil tiene su propio expediente independiente.',
              accion: Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () => _pedirControl(context),
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: const Text('Cumplí 18: pedir mi perfil'),
                ),
                FilledButton.icon(
                  onPressed: () => _nuevoPerfil(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar dependiente'),
                ),
              ]),
            ),
            if (s.cargando && s.perfiles.isEmpty) const VistaCargando(),
            Wrap(spacing: 16, runSpacing: 16, children: [
              for (final p in s.perfiles)
                SizedBox(
                  width: 340,
                  child: BwTarjeta(
                    borde: p.id == s.seleccionado?.id ? AppColors.primario : null,
                    onTap: () => context.read<PerfilActivoCubit>().seleccionar(p.id),
                    child: Row(children: [
                      AvatarIniciales(p.nombreCompleto, radio: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('${p.etiqueta} · ${p.edad} años${p.cedula != null ? ' · ${p.cedula}' : ''}',
                              style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
                          const SizedBox(height: 8),
                          if (p.puedeIndependizarse && !p.solicitudControlPendiente) ...[
                            const ChipEstado('Mayor de edad: puede pedir el control de su perfil', icono: Icons.how_to_reg_outlined, color: AppColors.marino),
                            const SizedBox(height: 6),
                          ],
                          if (p.solicitudControlPendiente) ...[
                            _SolicitudControl(perfil: p),
                            const SizedBox(height: 6),
                          ],
                          if (p.id == s.seleccionado?.id)
                            const ChipEstado('Perfil activo', icono: Icons.check_circle)
                          else
                            const Text('Toca para usar este perfil', style: TextStyle(color: AppColors.primario, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      );
    });
  }

  /// El dependiente, ya con su propia cuenta, pide el perfil que creó su titular.
  Future<void> _pedirControl(BuildContext context) async {
    final datos = await showDialog<(String, DateTime)>(context: context, builder: (_) => const _DialogoPedirControl());
    if (datos == null || !context.mounted) return;
    final error = await intentar(() => sl<ControlDePerfil>().solicitar(datos.$1, datos.$2));
    if (!context.mounted) return;
    mostrarMensaje(
      context,
      error ?? 'Solicitud enviada. Quien gestiona tu perfil debe aprobarla desde Mi familia.',
      error: error != null,
    );
  }

  Future<void> _nuevoPerfil(BuildContext context) async {
    final datos = await showDialog<NuevoPerfil>(context: context, builder: (_) => const _DialogoPerfil());
    if (datos == null || !context.mounted) return;
    final error = await context.read<PerfilActivoCubit>().crear(datos);
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Perfil de ${datos.nombres} creado', error: error != null);
  }
}

class _DialogoPerfil extends StatefulWidget {
  const _DialogoPerfil();
  @override
  State<_DialogoPerfil> createState() => _DialogoPerfilState();
}

class _DialogoPerfilState extends State<_DialogoPerfil> {
  final _form = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _cedula = TextEditingController();
  String _parentesco = 'HIJO';
  String _sexo = 'M';
  DateTime? _nacimiento;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo perfil dependiente'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final p in const ['HIJO', 'HIJA', 'MADRE', 'PADRE', 'CONYUGE', 'OTRO'])
                  ChoiceChip(label: Text(p[0] + p.substring(1).toLowerCase()), selected: _parentesco == p, onSelected: (_) => setState(() => _parentesco = p)),
              ]),
              const SizedBox(height: 14),
              TextFormField(controller: _nombres, decoration: AppTheme.campo('Nombres'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null),
              const SizedBox(height: 10),
              TextFormField(controller: _apellidos, decoration: AppTheme.campo('Apellidos'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null),
              const SizedBox(height: 10),
              TextFormField(controller: _cedula, decoration: AppTheme.campo('Cédula (opcional para menores)')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(_nacimiento == null ? 'Fecha de nacimiento' : Formatos.fechaCorta(_nacimiento!)),
                    onPressed: () async {
                      final f = await showDatePicker(context: context, initialDate: DateTime(2015), firstDate: DateTime(1900), lastDate: DateTime.now());
                      if (f != null) setState(() => _nacimiento = f);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, children: [
                for (final (v, e) in const [('F', 'Femenino'), ('M', 'Masculino')])
                  ChoiceChip(label: Text(e), selected: _sexo == v, onSelected: (_) => setState(() => _sexo = v)),
              ]),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate() || _nacimiento == null) return;
            Navigator.pop(
              context,
              NuevoPerfil(
                nombres: _nombres.text.trim(),
                apellidos: _apellidos.text.trim(),
                parentesco: _parentesco,
                fechaNacimiento: _nacimiento!,
                sexo: _sexo,
                cedula: _cedula.text.trim(),
              ),
            );
          },
          child: const Text('Crear perfil'),
        ),
      ],
    );
  }
}

/// El titular ve el pedido del dependiente mayor de edad y decide si le entrega el perfil.
class _SolicitudControl extends StatelessWidget {
  const _SolicitudControl({required this.perfil});
  final Perfil perfil;

  Future<void> _responder(BuildContext context, {required bool aprobar}) async {
    final ok = await confirmar(
      context,
      titulo: aprobar ? 'Entregar el perfil de ${perfil.nombres}' : 'Rechazar la solicitud',
      mensaje: aprobar
          ? '${perfil.nombres} ya es mayor de edad. El perfil y todo su expediente pasarán a su propia cuenta y dejarás de verlo aquí.'
          : 'El perfil seguirá en tu cuenta. ${perfil.nombres} podrá pedirlo de nuevo más adelante.',
      accion: aprobar ? 'Entregar perfil' : 'Rechazar',
      peligro: !aprobar,
    );
    if (!ok || !context.mounted) return;
    final control = sl<ControlDePerfil>();
    final error = await intentar(() => aprobar ? control.aprobar(perfil.id) : control.rechazar(perfil.id));
    if (!context.mounted) return;
    mostrarMensaje(
      context,
      error ?? (aprobar ? 'Perfil entregado a ${perfil.nombres}' : 'Solicitud rechazada'),
      error: error != null,
    );
    if (error == null) await context.read<PerfilActivoCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.ambarSuave, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${perfil.nombres} pidió gestionar su propio perfil.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ambarOscuro)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          FilledButton(onPressed: () => _responder(context, aprobar: true), child: const Text('Entregar perfil')),
          TextButton(onPressed: () => _responder(context, aprobar: false), child: const Text('Rechazar')),
        ]),
      ]),
    );
  }
}

class _DialogoPedirControl extends StatefulWidget {
  const _DialogoPedirControl();
  @override
  State<_DialogoPedirControl> createState() => _DialogoPedirControlState();
}

class _DialogoPedirControlState extends State<_DialogoPedirControl> {
  final _cedula = TextEditingController();
  DateTime? _nacimiento;

  @override
  void dispose() {
    _cedula.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _cedula.text.trim().isNotEmpty && _nacimiento != null;
    return AlertDialog(
      title: const Text('Pedir el control de mi perfil'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Si tu familia creó tu perfil cuando eras menor de edad, al cumplir 18 años puedes pasarlo a tu propia cuenta '
            'con todo tu expediente. Escribe la cédula y la fecha de nacimiento que tiene ese perfil.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(controller: _cedula, onChanged: (_) => setState(() {}), decoration: AppTheme.campo('Cédula')),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.cake_outlined),
            label: Text(_nacimiento == null ? 'Fecha de nacimiento' : Formatos.fechaCorta(_nacimiento!)),
            onPressed: () async {
              final f = await showDatePicker(context: context, initialDate: DateTime(2007), firstDate: DateTime(1900), lastDate: DateTime.now());
              if (f != null) setState(() => _nacimiento = f);
            },
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        FilledButton(
          onPressed: listo ? () => Navigator.pop(context, (_cedula.text.trim(), _nacimiento!)) : null,
          child: const Text('Enviar solicitud'),
        ),
      ],
    );
  }
}
