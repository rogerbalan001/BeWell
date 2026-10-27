import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/historia_clinica.dart';
import '../../domain/usecases/historia_clinica_usecases.dart';
import '../cubit/historia_clinica_cubit.dart';
import '../widgets/historia_widgets.dart';
import 'antecedentes_form_page.dart';
import 'consulta_form_page.dart';

/// Historia clínica. Si [pacienteId] es nulo se usa el perfil familiar activo.
class HistoriaClinicaPage extends StatelessWidget {
  const HistoriaClinicaPage({super.key, this.pacienteId});
  final String? pacienteId;

  @override
  Widget build(BuildContext context) {
    if (pacienteId != null) {
      return BlocProvider(create: (_) => sl<HistoriaClinicaCubit>()..cargar(pacienteId!), child: const _Vista());
    }
    return BlocBuilder<PerfilActivoCubit, PerfilesState>(
      buildWhen: (a, b) => a.seleccionado?.id != b.seleccionado?.id,
      builder: (context, s) {
        final id = s.seleccionado?.id;
        if (id == null) return const VistaCargando();
        return BlocProvider(key: ValueKey(id), create: (_) => sl<HistoriaClinicaCubit>()..cargar(id), child: const _Vista());
      },
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoriaClinicaCubit, Recurso<HistoriaClinica>>(builder: (context, estado) {
      final cubit = context.read<HistoriaClinicaCubit>();
      return switch (estado) {
        RecursoError(:final mensaje) => VistaError(mensaje, reintentar: cubit.recargar),
        RecursoListo(:final datos) => _Contenido(datos),
        _ => const VistaCargando(),
      };
    });
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido(this.h);
  final HistoriaClinica h;

  @override
  Widget build(BuildContext context) {
    final esTitular = h.acceso.esTitular;
    final ancho = MediaQuery.sizeOf(context).width;
    final a = h.antecedentes;

    final cabecera = BwTarjeta(
      padding: const EdgeInsets.all(24),
      child: Wrap(spacing: 20, runSpacing: 16, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          AvatarIniciales(h.pacienteNombre, radio: 30),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.pacienteNombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            if (a?.numeroHistoria != null)
              Text('N.º de historia ${a!.numeroHistoria}', style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(
              [
                '${h.edad} años',
                if (h.sexo.isNotEmpty) h.esFemenino ? 'Femenino' : (h.sexo == 'M' ? 'Masculino' : 'Otro'),
                if (h.cedula != null) 'C.I. ${h.cedula}',
                if (a?.grupoSanguineo != null) 'Grupo ${a!.grupoSanguineo}',
              ].join(' · '),
              style: const TextStyle(color: AppColors.pizarra),
            ),
            if (a?.actualizadoEn != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Antecedentes actualizados ${Formatos.relativo(a!.actualizadoEn!)}${a.actualizadoPorMedico ? ' por un médico' : ''}',
                  style: const TextStyle(color: AppColors.pizarraClara, fontSize: 12.5),
                ),
              ),
          ]),
        ]),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            onPressed: () async {
              final error = await intentar(() async {
                final url = await sl<ObtenerHistoriaClinica>().exportarPdf(h.pacienteId);
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              });
              if (error != null && context.mounted) mostrarMensaje(context, error, error: true);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Exportar PDF'),
          ),
          if (h.puedeRegistrarConsulta)
            FilledButton.tonalIcon(
              onPressed: () => _nuevaConsulta(context),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Nueva consulta'),
            ),
          OutlinedButton.icon(
            onPressed: () => context.push(esTitular ? '/expediente' : '/medico/pacientes/${h.pacienteId}'),
            icon: const Icon(Icons.timeline),
            label: const Text('Ver expediente'),
          ),
        ]),
      ]),
    );

    final alergias = (a != null && a.alergicos.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BwTarjeta(
              color: AppColors.errorSuave,
              borde: AppColors.error.withAlpha(60),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Alergias: ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: a.alergicos.join(', ')),
                  ]), style: const TextStyle(color: AppColors.error)),
                ),
              ]),
            ),
          )
        : const SizedBox.shrink();

    final antecedentes = SeccionTarjeta(
      titulo: 'Antecedentes',
      subtitulo: esTitular ? 'Tu información médica de base. Tus médicos autorizados la ven.' : 'Secciones III a V de la historia',
      icono: Icons.history_edu_outlined,
      accion: h.puedeEditarAntecedentes && a != null
          ? IconButton.filledTonal(tooltip: 'Editar antecedentes', icon: const Icon(Icons.edit_outlined), onPressed: () => _editarAntecedentes(context, a))
          : null,
      child: a == null
          ? const Text('El paciente no te dio acceso a la sección Diagnósticos, donde están los antecedentes.', style: TextStyle(color: AppColors.pizarra))
          : a.vacio
              ? VistaVacia(
                  icono: Icons.assignment_outlined,
                  titulo: 'Aún no hay antecedentes registrados',
                  mensaje: h.puedeEditarAntecedentes ? 'Completa alergias, enfermedades, cirugías y medicamentos.' : null,
                  accion: h.puedeEditarAntecedentes
                      ? FilledButton.icon(onPressed: () => _editarAntecedentes(context, a), icon: const Icon(Icons.edit_note), label: const Text('Completar ahora'))
                      : null,
                )
              : _Antecedentes(a, femenino: h.esFemenino),
    );

    final consultas = SeccionTarjeta(
      titulo: 'Consultas',
      subtitulo: 'Anamnesis, examen físico, diagnóstico y plan (secciones I a XII)',
      icono: Icons.medical_information_outlined,
      child: !h.veConsultas
          ? const Text('El paciente no te dio acceso a la sección Consultas.', style: TextStyle(color: AppColors.pizarra))
          : h.consultas.isEmpty
              ? const VistaVacia(icono: Icons.event_busy_outlined, titulo: 'Sin consultas registradas', mensaje: 'Los médicos registran aquí la historia de cada consulta.')
              : Column(children: [
                  for (final c in h.consultas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TarjetaConsulta(consulta: c, alCorregir: c.editable ? () => _corregir(context, c) : null),
                    ),
                ]),
    );

    return RefreshIndicator(
      onRefresh: context.read<HistoriaClinicaCubit>().recargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContenidoCentrado(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(antetitulo: 'Historia clínica', titulo: esTitular ? 'Mi historia clínica' : 'Historia clínica del paciente'),
            cabecera,
            const SizedBox(height: 20),
            alergias,
            if (ancho >= 1050)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 420, child: antecedentes),
                const SizedBox(width: 24),
                Expanded(child: consultas),
              ])
            else ...[
              antecedentes,
              const SizedBox(height: 16),
              consultas,
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _editarAntecedentes(BuildContext context, Antecedentes a) async {
    final cubit = context.read<HistoriaClinicaCubit>();
    final guardado = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AntecedentesFormPage(pacienteId: h.pacienteId, inicial: a, femenino: h.esFemenino, autoReportado: h.acceso.esTitular),
    ));
    if (guardado == true) cubit.recargar();
  }

  Future<void> _nuevaConsulta(BuildContext context) async {
    final cubit = context.read<HistoriaClinicaCubit>();
    final guardado = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ConsultaFormPage(pacienteId: h.pacienteId, pacienteNombre: h.pacienteNombre),
    ));
    if (guardado == true) cubit.recargar();
  }

  Future<void> _corregir(BuildContext context, ConsultaClinica c) async {
    final cubit = context.read<HistoriaClinicaCubit>();
    final guardado = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ConsultaFormPage(pacienteId: h.pacienteId, pacienteNombre: h.pacienteNombre, existente: c),
    ));
    if (guardado == true) cubit.recargar();
  }
}

class _Antecedentes extends StatelessWidget {
  const _Antecedentes(this.a, {required this.femenino});
  final Antecedentes a;
  final bool femenino;

  static const _iconos = <String, IconData>{
    'Inmunizaciones': Icons.vaccines_outlined,
    'Enfermedades de la infancia': Icons.child_care,
    'Alergias': Icons.warning_amber_rounded,
    'Médicos': Icons.coronavirus_outlined,
    'Quirúrgicos': Icons.healing_outlined,
    'Traumatológicos': Icons.personal_injury_outlined,
    'Transfusionales': Icons.bloodtype_outlined,
    'Epidemiológicos': Icons.public,
    'Medicamentos actuales': Icons.medication_outlined,
  };

  @override
  Widget build(BuildContext context) {
    Widget titulo(String t) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Text(t.toUpperCase(), style: const TextStyle(color: AppColors.primario, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        );
    final g = a.ginecoObstetricos;
    // Solo se muestran los grupos con datos: la historia queda resumida.
    final personales = [
      for (final e in a.personales.entries)
        if (e.value.isNotEmpty)
          GrupoAntecedentes(
            titulo: e.key,
            icono: _iconos[e.key] ?? Icons.circle_outlined,
            valores: e.value,
            color: e.key == 'Alergias' ? AppColors.error : AppColors.primario,
          ),
      if (femenino && g != null)
        GrupoAntecedentes(
          titulo: 'Ginecobstétricos',
          icono: Icons.pregnant_woman,
          color: AppColors.ambar,
          valores: [
            g.formula,
            if (g.menarquia != null) 'Menarquia: ${g.menarquia}',
            if (g.ultimaMenstruacion != null) 'FUM: ${g.ultimaMenstruacion}',
            if (g.metodoAnticonceptivo != null) 'Anticoncepción: ${g.metodoAnticonceptivo}',
          ],
        ),
    ];
    final habitos = [
      for (final e in habitosLegibles.entries)
        if (a.habitos[e.key] != null) '${e.value}: ${a.habitos[e.key]}',
    ];
    final sociales = [
      for (final e in datosSocialesLegibles.entries)
        if (a.datosSociales[e.key] != null) '${e.value}: ${a.datosSociales[e.key]}',
    ];
    final bloques = <Widget>[
      if (sociales.isNotEmpty) ...[
        titulo('Identificación'),
        GrupoAntecedentes(titulo: 'Datos sociales', icono: Icons.badge_outlined, valores: sociales),
      ],
      if (personales.isNotEmpty) ...[
        titulo('III. Antecedentes personales'),
        for (var i = 0; i < personales.length; i++) ...[if (i > 0) const SizedBox(height: 10), personales[i]],
      ],
      if (a.familiares.isNotEmpty) ...[
        titulo('IV. Antecedentes familiares'),
        GrupoAntecedentes(titulo: 'Familiares', icono: Icons.family_restroom, valores: a.familiares),
      ],
      if (habitos.isNotEmpty) ...[
        titulo('V. Historia personal y social'),
        GrupoAntecedentes(titulo: 'Hábitos', icono: Icons.self_improvement, valores: habitos, color: AppColors.verdeOscuro),
      ],
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final b in bloques) ...[
        if (b is Padding && bloques.first != b) const Divider(height: 22),
        b,
      ],
    ]);
  }
}
