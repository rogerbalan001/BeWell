import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';
import '../../domain/usecases/expediente_usecases.dart';

/// El médico refiere al paciente a un especialista de la red (requiere aprobación del paciente).
Future<void> mostrarDialogoReferir(BuildContext context, {required String pacienteId, required String pacienteNombre}) async {
  final medicos = await sl<BuscarEspecialistas>()().catchError((_) => <Medico>[]);
  if (!context.mounted) return;
  Medico? destino;
  final motivo = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Referir a $pacienteNombre'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Especialista de la red', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final m in medicos)
                  ChoiceChip(
                    avatar: AvatarIniciales(m.nombreCompleto, radio: 10),
                    label: Text('${m.nombreCompleto} · ${m.especialidad}'),
                    selected: destino?.id == m.id,
                    onSelected: (_) => setLocal(() => destino = m),
                  ),
              ]),
              const SizedBox(height: 14),
              TextField(controller: motivo, maxLines: 4, decoration: AppTheme.campo('Nota clínica para el especialista')),
              const SizedBox(height: 8),
              const Text('El paciente debe aprobar que se comparta su expediente. Luego el especialista podrá proponerle horarios.',
                  style: TextStyle(fontSize: 12)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar referencia')),
        ],
      ),
    ),
  );
  final elegido = destino;
  if (ok != true || elegido == null || !context.mounted) return;
  final error = await intentar(() => sl<GestionarReferencias>().referir(pacienteId, elegido.id, motivo.text.trim()));
  if (!context.mounted) return;
  mostrarMensaje(context, error ?? 'Referencia enviada; el paciente recibirá una notificación', error: error != null);
}
