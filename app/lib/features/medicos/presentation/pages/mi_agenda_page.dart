import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/medico.dart';
import '../../domain/usecases/medicos_usecases.dart';
import '../cubit/medicos_cubits.dart';

const _dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

/// HU médico: configurar horario y política de cancelación.
class MiAgendaPage extends StatelessWidget {
  const MiAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MiPerfilMedicoCubit>()..cargar(),
      child: BlocBuilder<MiPerfilMedicoCubit, Recurso<Medico>>(builder: (context, estado) {
        return switch (estado) {
          RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<MiPerfilMedicoCubit>().cargar()),
          RecursoListo(:final datos) => _Editor(datos, key: ValueKey(datos)),
          _ => const VistaCargando(),
        };
      }),
    );
  }
}

class _Dia {
  _Dia(this.activo, this.inicio, this.fin);
  bool activo;
  String inicio;
  String fin;
}

class _Editor extends StatefulWidget {
  const _Editor(this.medico, {super.key});
  final Medico medico;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final Map<int, List<_Dia>> _bloques;
  late int _duracion;
  late Set<String> _modalidades;
  late String _politica;
  List<PoliticaCancelacion> _catalogo = const [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final h = widget.medico.horario;
    _duracion = h.isEmpty ? 30 : h.first.duracionCitaMin;
    _bloques = {
      for (var d = 0; d < 7; d++)
        d: h.where((b) => b.diaSemana == d).map((b) => _Dia(true, b.horaInicio, b.horaFin)).toList(),
    };
    for (var d = 1; d <= 5; d++) {
      if (_bloques[d]!.isEmpty) _bloques[d] = [_Dia(false, '08:00', '12:00')];
    }
    _modalidades = widget.medico.modalidades.toSet();
    _politica = widget.medico.politica.tipo;
    sl<ObtenerCatalogoPoliticas>()().then((c) {
      if (mounted) setState(() => _catalogo = c);
    }).catchError((_) {});
  }

  Future<String?> _elegirHora(String actual) async {
    final partes = actual.split(':');
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1])));
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final bloques = <BloqueHorario>[
      for (final entrada in _bloques.entries)
        for (final b in entrada.value.where((x) => x.activo))
          BloqueHorario(diaSemana: entrada.key, horaInicio: b.inicio, horaFin: b.fin, duracionCitaMin: _duracion),
    ];
    final error = await intentar(() async {
      await sl<ConfigurarHorario>()(bloques, _modalidades.toList());
      await sl<ConfigurarPoliticaCancelacion>()(_politica);
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarMensaje(context, error ?? 'Agenda actualizada. Los pacientes ya ven tus nuevos horarios.', error: error != null);
    if (error == null) context.read<MiPerfilMedicoCubit>().cargar(silencioso: true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 900,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Encabezado(
            antetitulo: 'Mi agenda',
            titulo: 'Horario y política de cancelación',
            descripcion: 'Define cuándo atiendes y cómo se calculan los reembolsos. La política se muestra al paciente antes de confirmar.',
            accion: FilledButton.icon(onPressed: _guardando ? null : _guardar, icon: const Icon(Icons.save_outlined), label: const Text('Guardar cambios')),
          ),
          SeccionTarjeta(
            titulo: 'Horario semanal',
            subtitulo: 'Hora local (Caracas, UTC−4)',
            icono: Icons.schedule,
            child: Column(children: [
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Text('Duración de cada cita:', style: TextStyle(fontWeight: FontWeight.w600)),
                for (final m in const [15, 20, 30, 45, 60])
                  ChoiceChip(label: Text('$m min'), selected: _duracion == m, onSelected: (_) => setState(() => _duracion = m)),
              ]),
              const SizedBox(height: 12),
              for (var d = 1; d <= 7; d++) _filaDia(d % 7),
            ]),
          ),
          const SizedBox(height: 16),
          SeccionTarjeta(
            titulo: 'Modalidades',
            icono: Icons.devices_outlined,
            child: Wrap(spacing: 8, children: [
              for (final (valor, etiqueta) in const [('PRESENCIAL', 'Presencial'), ('VIRTUAL', 'En línea / videollamada')])
                FilterChip(
                  label: Text(etiqueta),
                  selected: _modalidades.contains(valor),
                  onSelected: (s) => setState(() {
                    if (s) {
                      _modalidades.add(valor);
                    } else if (_modalidades.length > 1) {
                      _modalidades.remove(valor);
                    }
                  }),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          SeccionTarjeta(
            titulo: 'Política de cancelación',
            subtitulo: 'Se copia en cada cita al momento de reservar',
            icono: Icons.policy_outlined,
            child: Column(children: [
              for (final p in _catalogo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BwTarjeta(
                    padding: const EdgeInsets.all(16),
                    color: _politica == p.tipo ? AppColors.superficieAzul2 : AppColors.superficieAzul,
                    borde: _politica == p.tipo ? AppColors.primario : Colors.transparent,
                    onTap: () => setState(() => _politica = p.tipo),
                    child: Row(children: [
                      Icon(_politica == p.tipo ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primario),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(p.descripcion, style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
                        ]),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _filaDia(int dia) {
    final bloques = _bloques[dia]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text(_dias[dia], style: const TextStyle(fontWeight: FontWeight.w600)))),
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final b in bloques)
              InputChip(
                selected: b.activo,
                showCheckmark: false,
                avatar: Icon(b.activo ? Icons.check_circle : Icons.circle_outlined, size: 18, color: b.activo ? AppColors.primario : AppColors.pizarraClara),
                label: Text('${b.inicio} – ${b.fin}'),
                onPressed: () => setState(() => b.activo = !b.activo),
                onDeleted: () => setState(() => bloques.remove(b)),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            TextButton.icon(
              onPressed: () async {
                final inicio = await _elegirHora(bloques.isEmpty ? '08:00' : bloques.last.fin);
                if (inicio == null) return;
                final fin = await _elegirHora(inicio);
                if (fin == null) return;
                setState(() => bloques.add(_Dia(true, inicio, fin)));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Bloque'),
            ),
          ]),
        ),
      ]),
    );
  }
}
