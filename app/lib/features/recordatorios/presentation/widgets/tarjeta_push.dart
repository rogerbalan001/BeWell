import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/push/notificaciones_push.dart';
import '../../../../core/push/push_navegador.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';

/// HU: el paciente autoriza las notificaciones en su teléfono y desde ahí le llegan
/// los recordatorios como push, aunque no abra la app.
class TarjetaPush extends StatefulWidget {
  const TarjetaPush({super.key});

  @override
  State<TarjetaPush> createState() => _TarjetaPushState();
}

class _TarjetaPushState extends State<TarjetaPush> {
  bool _ocupado = false;
  bool _suscrito = false;

  String get _permiso => permisoPush;

  Future<void> _activar() async {
    setState(() => _ocupado = true);
    var concedido = false;
    final error = await intentar(() async => concedido = await sl<NotificacionesPush>().activar());
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _suscrito = error == null && concedido;
    });
    mostrarMensaje(
      context,
      error ?? (concedido ? 'Listo: tus recordatorios llegarán como notificación a este teléfono.' : 'No diste permiso de notificaciones en este navegador.'),
      error: error != null || !concedido,
    );
  }

  Future<void> _probar() async {
    setState(() => _ocupado = true);
    var enviadas = 0;
    final error = await intentar(() async => enviadas = await sl<NotificacionesPush>().probar());
    if (!mounted) return;
    setState(() => _ocupado = false);
    mostrarMensaje(
      context,
      error ?? (enviadas > 0 ? 'Te enviamos una notificación de prueba.' : 'Activa primero las notificaciones en este teléfono.'),
      error: error != null || enviadas == 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final disponible = pushDisponible;
    final permiso = disponible ? _permiso : 'no-soportado';
    final activas = permiso == 'granted';
    final (texto, color) = switch (permiso) {
      'granted' => (_suscrito ? 'Activadas en este teléfono' : 'Permiso concedido en este teléfono', AppColors.verdeOscuro),
      'denied' => ('Bloqueadas: actívalas en los ajustes del navegador', AppColors.error),
      'default' => ('Todavía no las activas en este teléfono', AppColors.ambar),
      _ => ('Este navegador no admite notificaciones push', AppColors.pizarraClara),
    };
    return SeccionTarjeta(
      titulo: 'Notificaciones en el teléfono',
      icono: Icons.phonelink_ring_outlined,
      subtitulo: 'Cada recordatorio también te llega como notificación, aunque no tengas BeWell abierta. '
          'Al tocarla se abre la pantalla relacionada.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ChipEstado(texto, color: color, icono: activas ? Icons.notifications_active : Icons.notifications_none),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: !disponible || permiso == 'denied' || _ocupado ? null : _activar,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(activas ? 'Volver a registrar este teléfono' : 'Activar notificaciones'),
          ),
          OutlinedButton.icon(
            onPressed: !disponible || !activas || _ocupado ? null : _probar,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Enviar una prueba'),
          ),
        ]),
        if (!disponible || permiso == 'default') ...[
          const SizedBox(height: 10),
          const Text(
            'En iPhone, primero agrega BeWell a la pantalla de inicio (Compartir → Agregar a inicio) y ábrela desde ahí.',
            style: TextStyle(fontSize: 12, color: AppColors.pizarraClara),
          ),
        ],
      ]),
    );
  }
}
