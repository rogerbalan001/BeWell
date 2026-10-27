import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/estado/recurso.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/bw_widgets.dart';
import '../domain/notificaciones.dart';
import 'notificaciones_cubit.dart';

IconData _icono(String tipo) => switch (tipo) {
      'CITA' => Icons.event_note_outlined,
      'EXAMEN' => Icons.biotech_outlined,
      'RECIPE' => Icons.receipt_long_outlined,
      'REFERENCIA' => Icons.forward_to_inbox_outlined,
      'EMERGENCIA' => Icons.emergency_outlined,
      'VERIFICACION' => Icons.verified_outlined,
      'PERMISO' => Icons.lock_open_outlined,
      'RECORDATORIO' => Icons.alarm_outlined,
      _ => Icons.notifications_none,
    };

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  void _abrir(BuildContext context, Notificacion n) {
    context.read<NotificacionesCubit>().marcarLeida(n.id);
    final d = n.datos;
    if (d['citaId'] != null) {
      context.push('/citas/${d['citaId']}');
    } else if (n.tipo == 'RECORDATORIO' && d['tipo'] == 'MEDICAMENTOS') {
      context.push('/recipes');
    } else if (n.tipo == 'RECORDATORIO' && d['tipo'] == 'EXAMENES') {
      context.push('/examenes');
    } else if (n.tipo == 'REFERENCIA') {
      context.push('/referencias');
    } else if (n.tipo == 'EXAMEN' && d['examenId'] == null) {
      context.push('/examenes');
    } else if (n.tipo == 'RECIPE') {
      context.push('/recipes');
    } else if (n.tipo == 'VERIFICACION') {
      context.push('/medico/credenciales');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificacionesCubit>();
    return BlocBuilder<NotificacionesCubit, Recurso<BandejaNotificaciones>>(builder: (context, estado) {
      final bandeja = estado.datosOpcional;
      return SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Encabezado(
              antetitulo: 'Centro de avisos',
              titulo: 'Notificaciones',
              accion: TextButton.icon(onPressed: cubit.marcarTodas, icon: const Icon(Icons.done_all), label: const Text('Marcar todas como leídas')),
            ),
            if (bandeja == null)
              estado is RecursoError<BandejaNotificaciones> ? VistaError(estado.mensaje, reintentar: cubit.cargar) : const VistaCargando()
            else if (bandeja.items.isEmpty)
              const VistaVacia(icono: Icons.notifications_none, titulo: 'No tienes notificaciones')
            else
              for (final n in bandeja.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BwTarjeta(
                    color: n.leida ? AppColors.superficie : AppColors.superficieAzul2,
                    padding: const EdgeInsets.all(16),
                    onTap: () => _abrir(context, n),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(backgroundColor: Colors.white, child: Icon(_icono(n.tipo), color: AppColors.primario)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.w600 : FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(n.mensaje, style: const TextStyle(color: AppColors.pizarra, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(Formatos.relativo(n.creadaEn), style: const TextStyle(fontSize: 12, color: AppColors.pizarraClara)),
                        ]),
                      ),
                      if (!n.leida) Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.primario, shape: BoxShape.circle)),
                    ]),
                  ),
                ),
          ]),
        ),
      );
    });
  }
}
