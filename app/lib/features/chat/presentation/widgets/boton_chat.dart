import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../domain/usecases/chat_usecases.dart';

/// Botón "Chat con …" del detalle de la cita, con el contador de mensajes sin leer.
class BotonChat extends StatefulWidget {
  const BotonChat({super.key, required this.citaId, required this.etiqueta, this.conQuien});
  final String citaId;
  final String etiqueta;

  /// Nombre de la otra parte, para el encabezado del chat.
  final String? conQuien;

  @override
  State<BotonChat> createState() => _BotonChatState();
}

class _BotonChatState extends State<BotonChat> {
  int _noLeidos = 0;

  @override
  void initState() {
    super.initState();
    _contar();
  }

  Future<void> _contar() async {
    try {
      final n = await sl<ConversarEnCita>().noLeidosDe(widget.citaId);
      if (mounted) setState(() => _noLeidos = n);
    } catch (_) {
      // Sin contador si falla: el botón sigue funcionando.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () async {
        final con = widget.conQuien == null ? '' : '?con=${Uri.encodeComponent(widget.conQuien!)}';
        await context.push('/citas/${widget.citaId}/chat$con');
        _contar();
      },
      icon: Badge(
        isLabelVisible: _noLeidos > 0,
        label: Text('$_noLeidos'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      label: Text(_noLeidos > 0 ? '${widget.etiqueta} ($_noLeidos sin leer)' : widget.etiqueta),
    );
  }
}
