import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/expediente.dart';
import '../cubit/expediente_cubits.dart';

/// HU: decidir qué médico ve qué parte de mi historial y por cuánto tiempo.
class PermisosPage extends StatelessWidget {
  const PermisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final perfil = s.seleccionado;
        if (perfil == null) return const VistaCargando();
        return BlocProvider(
          key: ValueKey(perfil.id),
          create: (_) => sl<PermisosCubit>()..cargar(perfil.id),
          child: _Vista(pacienteId: perfil.id, nombre: perfil.nombreCompleto),
        );
      },
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista({required this.pacienteId, required this.nombre});
  final String pacienteId;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PermisosCubit>();
    return BlocBuilder<PermisosCubit, Recurso<DatosPermisos>>(builder: (context, estado) {
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 960,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Control de privacidad',
              titulo: 'Médicos autorizados',
              descripcion: 'Expediente de $nombre. Concede acceso por secciones y con fecha de vencimiento; revoca cuando quieras y el cambio aplica de inmediato.',
              accion: FilledButton.icon(onPressed: () => _conceder(context), icon: const Icon(Icons.person_add_alt), label: const Text('Conceder acceso')),
            ),
            switch (estado) {
              RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => cubit.cargar(pacienteId)),
              RecursoListo(:final datos) => Column(children: [
                  if (datos.permisos.isEmpty)
                    const VistaVacia(icono: Icons.lock_outline, titulo: 'Ningún médico tiene acceso', mensaje: 'Tu expediente es completamente privado.'),
                  for (final p in datos.permisos) _TarjetaPermiso(p, pacienteId: pacienteId),
                  const SizedBox(height: 16),
                  SeccionTarjeta(
                    titulo: 'Registro de auditoría de accesos',
                    subtitulo: 'Cada vez que un tercero consulta tu información',
                    icono: Icons.manage_search,
                    child: datos.accesos.isEmpty
                        ? const Text('Nadie ha consultado este expediente.', style: TextStyle(color: AppColors.pizarra))
                        : Column(children: [
                            for (final a in datos.accesos.take(20))
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(a.accesoEmergencia ? Icons.emergency_outlined : Icons.visibility_outlined,
                                    color: a.accesoEmergencia ? AppColors.error : AppColors.primario),
                                title: Text(_accion(a.accion)),
                                subtitle: Text('${_rol(a.rolActor)} · ${Formatos.fechaHora(a.fecha)}'),
                              ),
                          ]),
                  ),
                ]),
              _ => const VistaCargando(),
            },
          ]),
        ),
      );
    });
  }

  static String _accion(String a) => switch (a) {
        'LEER_LINEA_TIEMPO' => 'Consultó la línea de tiempo',
        'LEER_RESUMEN' => 'Abrió el expediente',
        'LEER_EVENTO' => 'Vio el detalle de un evento',
        'LISTAR_EXAMENES' || 'LEER_EXAMEN' => 'Consultó exámenes',
        'LEER_FICHA_EMERGENCIA' => 'Escaneó el QR de emergencia',
        'VERIFICAR_RECIPE' => 'Una farmacia verificó un récipe',
        _ => a,
      };

  static String _rol(String r) => switch (r) {
        'MEDICO' => 'Médico',
        'PERSONAL_EMERGENCIA' => 'Personal de emergencia',
        'ANONIMO' => 'Acceso público',
        'VERIFICADOR_PUBLICO' => 'Farmacia',
        _ => r,
      };

  Future<void> _conceder(BuildContext context) async {
    final medicos = await sl<BuscarEspecialistas>()().catchError((_) => <Medico>[]);
    if (!context.mounted) return;
    final permiso = await showDialog<NuevoPermiso>(context: context, builder: (_) => _DialogoPermiso(medicos));
    if (permiso == null || !context.mounted) return;
    final cubit = context.read<PermisosCubit>();
    final error = await intentar(() => cubit.gestion.conceder(pacienteId, permiso));
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Acceso concedido', error: error != null);
    cubit.cargar(pacienteId, silencioso: true);
  }
}

class _TarjetaPermiso extends StatelessWidget {
  const _TarjetaPermiso(this.p, {required this.pacienteId});
  final Permiso p;
  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PermisosCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        color: p.vigente ? AppColors.superficie : AppColors.superficieAzul,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AvatarIniciales(p.medico?.nombreCompleto ?? 'M', radio: 22, verificado: p.medico?.verificado ?? false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(p.medico?.nombreCompleto ?? 'Médico', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ChipEstado(
                  p.revocado ? 'Revocado' : (p.vigente ? (p.escritura ? 'Lectura y escritura' : 'Solo lectura') : 'Vencido'),
                  color: p.vigente ? AppColors.verde : AppColors.pizarraClara,
                ),
                if (p.origen == 'REFERENCIA') const ChipEstado('Por referencia', color: AppColors.primario),
              ]),
              Text(p.medico?.especialidad ?? '', style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final c in p.categorias) ChipEstado(categoriasClinicas[c] ?? c, color: AppColors.primario, fondo: AppColors.superficieAzul2),
              ]),
              const SizedBox(height: 6),
              Text('Válido hasta ${Formatos.fechaCorta(p.validoHasta)}', style: const TextStyle(fontSize: 12.5, color: AppColors.pizarra)),
            ]),
          ),
          if (p.vigente)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                final ok = await confirmar(context,
                    titulo: 'Revocar acceso', mensaje: '${p.medico?.nombreCompleto ?? 'El médico'} dejará de ver tu expediente de inmediato.', accion: 'Revocar', peligro: true);
                if (!ok || !context.mounted) return;
                final error = await intentar(() => cubit.gestion.revocar(p.id));
                if (!context.mounted) return;
                mostrarMensaje(context, error ?? 'Acceso revocado', error: error != null);
                cubit.cargar(pacienteId, silencioso: true);
              },
              child: const Text('Revocar'),
            ),
        ]),
      ),
    );
  }
}

class _DialogoPermiso extends StatefulWidget {
  const _DialogoPermiso(this.medicos);
  final List<Medico> medicos;
  @override
  State<_DialogoPermiso> createState() => _DialogoPermisoState();
}

class _DialogoPermisoState extends State<_DialogoPermiso> {
  Medico? _medico;
  final Set<String> _categorias = {'CONSULTAS', 'DIAGNOSTICOS', 'LABORATORIOS'};
  int _dias = 30;
  bool _escritura = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conceder acceso a un médico'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Médico', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final m in widget.medicos)
                ChoiceChip(label: Text('${m.nombreCompleto} · ${m.especialidad}'), selected: _medico?.id == m.id, onSelected: (_) => setState(() => _medico = m)),
            ]),
            const SizedBox(height: 14),
            const Text('Secciones que podrá ver', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in categoriasClinicas.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: _categorias.contains(e.key),
                  onSelected: (s) => setState(() => s ? _categorias.add(e.key) : _categorias.remove(e.key)),
                ),
            ]),
            const SizedBox(height: 14),
            const Text('Vigencia', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (final d in const [1, 7, 30, 90, 365])
                ChoiceChip(label: Text(d == 1 ? '24 horas' : '$d días'), selected: _dias == d, onSelected: (_) => setState(() => _dias = d)),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _escritura,
              onChanged: (v) => setState(() => _escritura = v),
              title: const Text('Permitir que agregue información'),
              subtitle: const Text('Notas, diagnósticos y resultados en las secciones elegidas'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _medico == null || _categorias.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    NuevoPermiso(
                      medicoId: _medico!.id,
                      categorias: _categorias.toList(),
                      validoHasta: DateTime.now().add(Duration(days: _dias)),
                      escritura: _escritura,
                    ),
                  ),
          child: const Text('Conceder'),
        ),
      ],
    );
  }
}
