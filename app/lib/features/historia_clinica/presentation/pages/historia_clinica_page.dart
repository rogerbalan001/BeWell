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
import '../../domain/entities/catalogo_historia.dart';
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

class _Contenido extends StatefulWidget {
  const _Contenido(this.h);
  final HistoriaClinica h;

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  /// 0: antecedentes (III–V), 1: consultas (I–II, VI–XII).
  int _pestana = 0;

  HistoriaClinica get h => widget.h;

  @override
  Widget build(BuildContext context) {
    final esTitular = h.acceso.esTitular;
    final a = h.antecedentes;

    final pestanas = SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        const ButtonSegment(value: 0, icon: Icon(Icons.history_edu_outlined), label: Text('Antecedentes')),
        ButtonSegment(value: 1, icon: const Icon(Icons.medical_information_outlined), label: Text('Consultas (${h.consultas.length})')),
      ],
      selected: {_pestana},
      onSelectionChanged: (s) => setState(() => _pestana = s.first),
    );

    return RefreshIndicator(
      onRefresh: context.read<HistoriaClinicaCubit>().recargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ContenidoCentrado(
          maxAncho: 1080,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Historia clínica integral',
              titulo: esTitular ? 'Mi historia clínica' : 'Historia clínica del paciente',
              accion: _acciones(context),
            ),
            _Identificacion(h),
            const SizedBox(height: 16),
            if (a != null && a.alergicos.isNotEmpty) ...[_BandaAlergias(a.alergicos), const SizedBox(height: 16)],
            Align(alignment: Alignment.centerLeft, child: pestanas),
            const SizedBox(height: 16),
            if (_pestana == 0) ..._antecedentes(context) else ..._consultas(context),
          ]),
        ),
      ),
    );
  }

  Widget _acciones(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
        if (h.puedeRegistrarConsulta)
          FilledButton.icon(onPressed: () => _nuevaConsulta(context), icon: const Icon(Icons.note_add_outlined), label: const Text('Nueva consulta')),
        OutlinedButton.icon(
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
        OutlinedButton.icon(
          onPressed: () => context.push(h.acceso.esTitular ? '/expediente' : '/medico/pacientes/${h.pacienteId}'),
          icon: const Icon(Icons.timeline),
          label: const Text('Expediente'),
        ),
      ]);

  List<Widget> _antecedentes(BuildContext context) {
    final a = h.antecedentes;
    if (a == null) {
      return const [
        BwTarjeta(child: Text('El paciente no te dio acceso a la sección Diagnósticos, donde están los antecedentes.', style: TextStyle(color: AppColors.pizarra))),
      ];
    }
    final editar = h.puedeEditarAntecedentes
        ? FilledButton.tonalIcon(onPressed: () => _editarAntecedentes(context, a), icon: const Icon(Icons.edit_outlined), label: const Text('Editar'))
        : null;
    if (a.vacio) {
      return [
        BwTarjeta(
          child: VistaVacia(
            icono: Icons.assignment_outlined,
            titulo: 'Aún no hay antecedentes registrados',
            mensaje: h.puedeEditarAntecedentes ? 'Completa la identificación y los antecedentes personales, familiares y sociales.' : null,
            accion: editar,
          ),
        ),
      ];
    }
    final g = a.ginecoObstetricos;
    final personales = <Widget>[
      for (final (n, campo) in antecedentesPersonales) ...[
        if (n == 11 && h.esFemenino) _gineco(g),
        ItemAntecedente(
          numero: n,
          titulo: campo.etiqueta,
          valores: a.lista(campo.clave),
          color: campo.clave == 'alergicos' ? AppColors.error : AppColors.primario,
        ),
      ],
    ];
    final familiares = [
      for (final campo in antecedentesFamiliares)
        if (campo.clave != 'otros' || (a.familiares['otros'] ?? const []).isNotEmpty)
          ItemAntecedente(titulo: campo.etiqueta, valores: a.familiares[campo.clave] ?? const [], color: AppColors.ambar),
    ];
    return [
      SeccionDocumento(
        numeral: 'III',
        titulo: 'Antecedentes personales',
        subtitulo: a.actualizadoEn == null
            ? null
            : 'Actualizados ${Formatos.relativo(a.actualizadoEn!)}${a.actualizadoPorMedico ? ' por un médico' : esTitular ? ' por ti' : ' por el paciente'}',
        accion: editar,
        child: RejillaAdaptable(minAncho: 300, espacio: 12, children: personales),
      ),
      const SizedBox(height: 16),
      SeccionDocumento(
        numeral: 'IV',
        titulo: 'Antecedentes familiares',
        child: RejillaAdaptable(minAncho: 300, espacio: 12, children: familiares),
      ),
      const SizedBox(height: 16),
      SeccionDocumento(
        numeral: 'V',
        titulo: 'Historia personal y social',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RejillaAdaptable(minAncho: 220, espacio: 16, children: [
            for (final campo in habitosCatalogo)
              if (a.habitos[campo.clave] != null || const ['alcohol', 'tabaco', 'drogas', 'actividadFisica', 'sueno', 'alimentacion'].contains(campo.clave))
                CampoDato(campo.etiqueta, a.habitos[campo.clave]),
          ]),
          const SizedBox(height: 16),
          ItemAntecedente(titulo: 'Medicamentos', valores: a.medicamentosActuales, color: AppColors.verdeOscuro),
        ]),
      ),
    ];
  }

  bool get esTitular => h.acceso.esTitular;

  Widget _gineco(GinecoObstetricos? g) {
    if (g == null) return const ItemAntecedente(numero: 10, titulo: 'Ginecobstétricos', valores: [], color: AppColors.ambar);
    return ItemAntecedente(
      numero: 10,
      titulo: 'Ginecobstétricos',
      valores: const [],
      color: AppColors.ambar,
      extra: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.formula, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.marino, letterSpacing: 0.5)),
        const Text('Gestas · partos · cesáreas · abortos', style: TextStyle(color: AppColors.pizarraClara, fontSize: 11.5)),
        const SizedBox(height: 6),
        for (final (e, v) in g.detalle)
          Text.rich(TextSpan(children: [
            TextSpan(text: '$e: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: v),
          ]), style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.marino)),
      ]),
    );
  }

  List<Widget> _consultas(BuildContext context) {
    if (!h.veConsultas) {
      return const [BwTarjeta(child: Text('El paciente no te dio acceso a la sección Consultas.', style: TextStyle(color: AppColors.pizarra)))];
    }
    if (h.consultas.isEmpty) {
      return [
        BwTarjeta(
          child: VistaVacia(
            icono: Icons.event_busy_outlined,
            titulo: 'Sin consultas registradas',
            mensaje: 'Aquí aparece la historia de cada consulta: anamnesis, examen físico, diagnóstico y plan.',
            accion: h.puedeRegistrarConsulta
                ? FilledButton.icon(onPressed: () => _nuevaConsulta(context), icon: const Icon(Icons.note_add_outlined), label: const Text('Nueva consulta'))
                : null,
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < h.consultas.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TarjetaConsulta(
            consulta: h.consultas[i],
            inicialmenteAbierta: i == 0,
            alCorregir: h.consultas[i].editable ? () => _corregir(context, h.consultas[i]) : null,
          ),
        ),
    ];
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

/// Encabezado del documento: paciente, número de historia e identificación completa.
class _Identificacion extends StatelessWidget {
  const _Identificacion(this.h);
  final HistoriaClinica h;

  @override
  Widget build(BuildContext context) {
    final a = h.antecedentes;
    final ds = a?.datosSociales ?? const <String, String>{};
    return BwTarjeta(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.marino, AppColors.primarioOscuro], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Wrap(spacing: 18, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withAlpha(36),
                child: Text(Formatos.iniciales(h.pacienteNombre), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.pacienteNombre, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(
                  [h.sexoLegible, '${h.edad} años', if (h.cedula != null) 'C.I. ${h.cedula}'].join(' · '),
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13.5),
                ),
              ]),
            ]),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (a?.numeroHistoria != null) _Pastilla(Icons.tag, 'N.º ${a!.numeroHistoria}'),
              if (a?.grupoSanguineo != null) _Pastilla(Icons.bloodtype_outlined, 'Grupo ${a!.grupoSanguineo}'),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('IDENTIFICACIÓN', style: TextStyle(color: AppColors.primario, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 14),
            RejillaAdaptable(minAncho: 200, espacio: 16, children: [
              CampoDato('Apellidos', h.apellidos),
              CampoDato('Nombres', h.nombres),
              CampoDato('Fecha de nacimiento', h.fechaNacimiento == null ? null : Formatos.fechaCorta(h.fechaNacimiento!)),
              CampoDato('Edad', '${h.edad} años'),
              for (final campo in camposIdentificacion) CampoDato(campo.etiqueta, ds[campo.clave]),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla(this.icono, this.texto);
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withAlpha(60))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, size: 15, color: Colors.white),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

class _BandaAlergias extends StatelessWidget {
  const _BandaAlergias(this.alergias);
  final List<String> alergias;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: AppColors.errorSuave, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.error.withAlpha(60))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.error),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(TextSpan(children: [
            const TextSpan(text: 'Alergias: ', style: TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: alergias.join(' · ')),
          ]), style: const TextStyle(color: AppColors.error, fontSize: 14)),
        ),
      ]),
    );
  }
}
