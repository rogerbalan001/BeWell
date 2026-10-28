import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/expediente.dart';
import '../../domain/usecases/expediente_usecases.dart';
import '../cubit/expediente_cubits.dart';
import '../widgets/linea_tiempo.dart';
import 'referir_dialogo.dart';

/// Expediente clínico digital. Si [pacienteId] es nulo se usa el perfil familiar activo.
class ExpedientePage extends StatelessWidget {
  const ExpedientePage({super.key, this.pacienteId});
  final String? pacienteId;

  @override
  Widget build(BuildContext context) {
    if (pacienteId != null) {
      return BlocProvider(create: (_) => sl<ExpedienteCubit>()..cargar(pacienteId!), child: const _Vista());
    }
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final id = s.seleccionado?.id;
        if (id == null) return const VistaCargando();
        return BlocProvider(key: ValueKey(id), create: (_) => sl<ExpedienteCubit>()..cargar(id), child: const _Vista());
      },
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpedienteCubit, Recurso<DatosExpediente>>(builder: (context, estado) {
      final cubit = context.read<ExpedienteCubit>();
      return switch (estado) {
        RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.recargar),
        RecursoListo(:final datos) => _Contenido(datos),
        _ => const VistaCargando(),
      };
    });
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido(this.d);
  final DatosExpediente d;

  @override
  Widget build(BuildContext context) {
    final r = d.resumen;
    final esTitular = r.acceso.esTitular;
    final ancho = MediaQuery.sizeOf(context).width;

    final cabecera = BwTarjeta(
      padding: const EdgeInsets.all(24),
      child: Wrap(spacing: 20, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          AvatarIniciales(r.pacienteNombre, radio: 34),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.pacienteNombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            Text('${r.edad} años${r.cedula != null ? ' · C.I. ${r.cedula}' : ''}', style: const TextStyle(color: AppColors.pizarra)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.fingerprint, size: 16, color: AppColors.primario),
              const SizedBox(width: 4),
              Text('ID único: ${r.codigo}', style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w700)),
            ]),
            if (esTitular)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Propiedad 100 % del paciente · viaja contigo entre médicos', style: TextStyle(color: AppColors.verdeOscuro, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
          ]),
        ]),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            onPressed: () async {
              final error = await intentar(() async {
                final url = await sl<ObtenerExpediente>().exportarPdf(r.pacienteId);
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              });
              if (error != null && context.mounted) mostrarMensaje(context, error, error: true);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Exportar PDF'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push(esTitular ? '/historia-clinica' : '/medico/pacientes/${r.pacienteId}/historia'),
            icon: const Icon(Icons.medical_information_outlined),
            label: const Text('Historia clínica'),
          ),
          if (esTitular)
            OutlinedButton.icon(onPressed: () => context.push('/expediente/permisos'), icon: const Icon(Icons.admin_panel_settings_outlined), label: const Text('Médicos autorizados')),
          if (!esTitular)
            OutlinedButton.icon(
              onPressed: () => context.push('/medico/pacientes/${r.pacienteId}/examenes?nombre=${Uri.encodeComponent(r.pacienteNombre)}'),
              icon: const Icon(Icons.biotech_outlined),
              label: const Text('Órdenes de exámenes'),
            ),
          if (!esTitular)
            OutlinedButton.icon(
              onPressed: () => mostrarDialogoReferir(context, pacienteId: r.pacienteId, pacienteNombre: r.pacienteNombre),
              icon: const Icon(Icons.forward_to_inbox_outlined),
              label: const Text('Referir a especialista'),
            ),
        ]),
      ]),
    );

    final filtros = Wrap(spacing: 8, runSpacing: 8, children: [
      ChoiceChip(label: const Text('Todo'), selected: d.filtro == null, onSelected: (_) => context.read<ExpedienteCubit>().filtrar(null)),
      for (final t in const ['CONSULTA', 'DIAGNOSTICO', 'EXAMEN', 'RECETA', 'VACUNA', 'CIRUGIA'])
        if (r.acceso.categorias.contains(_categoria(t)))
          ChoiceChip(label: Text(tiposEvento[t]!), selected: d.filtro == t, onSelected: (_) => context.read<ExpedienteCubit>().filtrar(t)),
    ]);

    final linea = SeccionTarjeta(
      titulo: 'Historial clínico interoperable',
      subtitulo: esTitular ? 'Consultas, diagnósticos, estudios y récipes de todas tus clínicas' : 'Solo ves las secciones que el paciente autorizó',
      icono: Icons.timeline,
      accion: _botonAgregar(context, r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        filtros,
        const SizedBox(height: 18),
        if (d.pagina.items.isEmpty)
          const VistaVacia(icono: Icons.history_toggle_off, titulo: 'Sin eventos para mostrar')
        else
          LineaTiempo(eventos: d.pagina.items),
      ]),
    );

    final lateral = Column(children: [
      SeccionTarjeta(
        titulo: 'Antecedentes',
        icono: Icons.history_edu_outlined,
        accion: r.acceso.puedeEscribir('DIAGNOSTICOS')
            ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editarAntecedentes(context, r))
            : null,
        child: r.antecedentes.isEmpty
            ? const Text('Sin antecedentes registrados.', style: TextStyle(color: AppColors.pizarra))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final a in r.antecedentes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.primario),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a)),
                    ]),
                  ),
              ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: esTitular ? 'Privacidad' : 'Tu acceso',
        icono: Icons.verified_user_outlined,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final c in r.acceso.categorias)
              ChipEstado(categoriasClinicas[c] ?? c, color: r.acceso.puedeEscribir(c) ? AppColors.verdeOscuro : AppColors.primario),
          ]),
          const SizedBox(height: 10),
          Text(
            esTitular
                ? 'Tú decides qué médico ve cada sección y hasta cuándo. Cada acceso queda auditado.'
                : 'En verde, las secciones donde también puedes registrar información.',
            style: const TextStyle(color: AppColors.pizarra, fontSize: 12.5),
          ),
        ]),
      ),
      if (esTitular) ...[
        const SizedBox(height: 16),
        BwTarjeta(
          onTap: () => context.push('/emergencia'),
          child: const Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ACCESO DE EMERGENCIA QR', style: TextStyle(color: AppColors.primario, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                SizedBox(height: 4),
                Text('Pase médico rápido', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Alergias y tipo de sangre sin desbloquear tu teléfono.', style: TextStyle(color: AppColors.pizarra, fontSize: 12.5)),
              ]),
            ),
            Icon(Icons.qr_code_2, size: 48, color: AppColors.marino),
          ]),
        ),
      ],
    ]);

    return RefreshIndicator(
      onRefresh: context.read<ExpedienteCubit>().recargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContenidoCentrado(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(antetitulo: 'Expediente clínico digital', titulo: esTitular ? 'Mi historial' : 'Expediente del paciente'),
            cabecera,
            const SizedBox(height: 20),
            if (ancho >= 1050)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: linea),
                const SizedBox(width: 24),
                SizedBox(width: 340, child: lateral),
              ])
            else ...[
              lateral,
              const SizedBox(height: 16),
              linea,
            ],
          ]),
        ),
      ),
    );
  }

  static String _categoria(String tipo) => switch (tipo) {
        'CONSULTA' => 'CONSULTAS',
        'DIAGNOSTICO' => 'DIAGNOSTICOS',
        'EXAMEN' => 'LABORATORIOS',
        'RECETA' => 'RECETAS',
        'VACUNA' => 'VACUNAS',
        _ => 'CIRUGIAS',
      };

  Widget? _botonAgregar(BuildContext context, ResumenExpediente r) {
    final tipos = <String>[
      for (final t in const ['CONSULTA', 'DIAGNOSTICO', 'VACUNA', 'CIRUGIA'])
        if (r.acceso.puedeEscribir(_categoria(t))) t,
    ];
    if (tipos.isEmpty) return null;
    return IconButton.filledTonal(
      tooltip: r.acceso.esTitular ? 'Registrar dato (auto-reportado)' : 'Agregar información clínica',
      icon: const Icon(Icons.add),
      onPressed: () => _agregarEvento(context, r, tipos),
    );
  }

  Future<void> _agregarEvento(BuildContext context, ResumenExpediente r, List<String> tipos) async {
    String tipo = tipos.first;
    DateTime fecha = DateTime.now();
    final titulo = TextEditingController();
    final resumen = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Agregar al expediente'),
          content: SizedBox(
            width: 460,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Wrap(spacing: 6, children: [
                for (final t in tipos) ChoiceChip(label: Text(tiposEvento[t]!), selected: tipo == t, onSelected: (_) => setLocal(() => tipo = t)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: titulo, decoration: AppTheme.campo('Título (p. ej. "Vacuna contra la influenza")')),
              const SizedBox(height: 10),
              TextField(controller: resumen, maxLines: 4, decoration: AppTheme.campo('Detalle')),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(Formatos.fechaCorta(fecha)),
                onPressed: () async {
                  final f = await showDatePicker(context: ctx, initialDate: fecha, firstDate: DateTime(1950), lastDate: DateTime.now());
                  if (f != null) setLocal(() => fecha = f);
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true || titulo.text.trim().isEmpty || !context.mounted) return;
    final error = await intentar(() => sl<AgregarInformacionClinica>()(
          r.pacienteId,
          NuevoEvento(tipo: tipo, titulo: titulo.text.trim(), resumen: resumen.text.trim(), fecha: fecha),
        ));
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Información agregada al expediente', error: error != null);
    if (error == null) context.read<ExpedienteCubit>().recargar();
  }

  Future<void> _editarAntecedentes(BuildContext context, ResumenExpediente r) async {
    final controlador = TextEditingController(text: r.antecedentes.join('\n'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Antecedentes'),
        content: SizedBox(
          width: 460,
          child: TextField(controller: controlador, maxLines: 8, decoration: AppTheme.campo('Uno por línea')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final lista = controlador.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final error = await intentar(() => sl<AgregarInformacionClinica>().antecedentes(r.pacienteId, lista));
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Antecedentes actualizados', error: error != null);
    if (error == null) context.read<ExpedienteCubit>().recargar();
  }
}
