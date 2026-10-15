import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../domain/entities/cita.dart';

/// Selector de fecha (píldoras por día) y hora (mañana / tarde) del diseño "Selección de horario".
class SelectorFranjas extends StatefulWidget {
  const SelectorFranjas({super.key, required this.franjas, required this.seleccionada, required this.alElegir});
  final List<Franja> franjas;
  final Franja? seleccionada;
  final ValueChanged<Franja> alElegir;

  @override
  State<SelectorFranjas> createState() => _SelectorFranjasState();
}

class _SelectorFranjasState extends State<SelectorFranjas> {
  DateTime? _dia;

  static DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

  List<DateTime> get _dias => widget.franjas.map((f) => _soloDia(f.inicio)).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    final dias = _dias;
    if (dias.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No hay horarios disponibles en los próximos días.', style: TextStyle(color: AppColors.pizarra)),
      );
    }
    final dia = _dia ?? (widget.seleccionada != null ? _soloDia(widget.seleccionada!.inicio) : dias.first);
    final delDia = widget.franjas.where((f) => _soloDia(f.inicio) == dia).toList();
    final manana = delDia.where((f) => f.inicio.hour < 12).toList();
    final tarde = delDia.where((f) => f.inicio.hour >= 12).toList();
    final hoy = _soloDia(DateTime.now());

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(Formatos.mesAnio(dia), style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: dias.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final d = dias[i];
            final activo = d == dia;
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => _dia = d),
              child: Container(
                width: 70,
                decoration: BoxDecoration(
                  color: activo ? AppColors.primario : AppColors.superficieAzul,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(Formatos.diaSemanaCorto(d), style: TextStyle(fontSize: 12, color: activo ? Colors.white70 : AppColors.pizarra)),
                  Text('${d.day}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: activo ? Colors.white : AppColors.marino)),
                  if (d == hoy)
                    Text('Hoy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: activo ? Colors.white : AppColors.primario)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 18),
      if (manana.isNotEmpty) _grupo('Horario mañana', Icons.wb_sunny_outlined, manana),
      if (tarde.isNotEmpty) _grupo('Horario tarde', Icons.nights_stay_outlined, tarde),
    ]);
  }

  Widget _grupo(String titulo, IconData icono, List<Franja> franjas) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icono, size: 18, color: AppColors.pizarra),
          const SizedBox(width: 6),
          Text('$titulo (${franjas.length} cupos)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final f in franjas)
            ChoiceChip(
              label: Text(Formatos.hora(f.inicio)),
              selected: widget.seleccionada == f,
              showCheckmark: false,
              shape: const StadiumBorder(),
              selectedColor: AppColors.primario,
              labelStyle: TextStyle(
                color: widget.seleccionada == f ? Colors.white : AppColors.marino,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => widget.alElegir(f),
            ),
        ]),
      ]),
    );
  }
}
