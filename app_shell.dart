import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/domain/entities/usuario_sesion.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../../notificaciones/domain/notificaciones.dart';
import '../../../notificaciones/presentation/notificaciones_cubit.dart';
import '../../../perfiles/presentation/widgets/selector_perfil.dart';

class _Destino {
  const _Destino(this.ruta, this.icono, this.titulo);
  final String ruta;
  final IconData icono;
  final String titulo;
}

List<_Destino> _destinos(UsuarioSesion? u) => [
      const _Destino('/inicio', Icons.home_outlined, 'Inicio'),
      if (u?.esPaciente ?? false) ...const [
        _Destino('/directorio', Icons.person_search_outlined, 'Directorio médico'),
        _Destino('/citas', Icons.event_note_outlined, 'Mis citas'),
        _Destino('/expediente', Icons.folder_shared_outlined, 'Expediente'),
        _Destino('/examenes', Icons.biotech_outlined, 'Exámenes'),
        _Destino('/recipes', Icons.receipt_long_outlined, 'Récipes'),
        _Destino('/emergencia', Icons.qr_code_2, 'Emergencia QR'),
        _Destino('/referencias', Icons.forward_to_inbox_outlined, 'Referencias'),
        _Destino('/perfiles', Icons.family_restroom, 'Mi familia'),
      ],
      if (u?.esMedico ?? false) ...const [
        _Destino('/citas', Icons.event_note_outlined, 'Agenda'),
        _Destino('/medico/pacientes', Icons.folder_shared_outlined, 'Mis pacientes'),
        _Destino('/referencias', Icons.forward_to_inbox_outlined, 'Referencias'),
        _Destino('/recipes', Icons.receipt_long_outlined, 'Récipes'),
        _Destino('/medico/agenda', Icons.schedule, 'Horario y política'),
        _Destino('/medico/credenciales', Icons.workspace_premium_outlined, 'Credenciales'),
      ],
      if (u?.esAdmin ?? false) const _Destino('/admin/verificaciones', Icons.verified_user_outlined, 'Verificaciones'),
    ];

/// Estructura principal: navegación lateral en escritorio y menú en móvil.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.ubicacion});
  final Widget child;
  final String ubicacion;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionCubit>().state.usuario;
    final destinos = _destinos(usuario);
    var indice = destinos.lastIndexWhere((d) => ubicacion == d.ruta || ubicacion.startsWith('${d.ruta}/'));
    if (indice < 0) indice = 0;
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= 1100;

    final barra = AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: escritorio ? 24 : 0,
      title: escritorio ? null : const BwLogo(tamano: 30),
      actions: [
        if (usuario?.esPaciente ?? false) Padding(padding: const EdgeInsets.only(right: 8), child: SelectorPerfil(compacto: ancho < 600)),
        const _Campana(),
        PopupMenuButton<String>(
          tooltip: 'Cuenta',
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primario,
            child: Text((usuario?.nombreMostrado ?? '?').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          onSelected: (v) async {
            if (v == 'salir') await context.read<SesionCubit>().cerrarSesion();
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text(usuario?.email ?? '')),
            const PopupMenuItem(value: 'salir', child: Row(children: [Icon(Icons.logout, size: 18), SizedBox(width: 8), Text('Cerrar sesión')])),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );

    if (escritorio) {
      return Scaffold(
        body: Row(children: [
          Container(
            width: 260,
            color: Colors.white,
            child: SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(padding: EdgeInsets.fromLTRB(24, 20, 24, 28), child: BwLogo(tamano: 34)),
                Expanded(
                  child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                    for (var i = 0; i < destinos.length; i++) _ItemNav(destinos[i], activo: i == indice),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: ChipEstado('Datos clínicos cifrados', color: AppColors.verdeOscuro, icono: Icons.lock_outline),
                ),
              ]),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.borde),
          Expanded(child: Scaffold(appBar: barra, body: child)),
        ]),
      );
    }

    return Scaffold(
      appBar: barra,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            const Padding(padding: EdgeInsets.fromLTRB(12, 8, 12, 20), child: BwLogo(tamano: 32)),
            for (var i = 0; i < destinos.length; i++)
              _ItemNav(destinos[i], activo: i == indice, alTocar: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
      body: child,
    );
  }
}

class _ItemNav extends StatelessWidget {
  const _ItemNav(this.destino, {required this.activo, this.alTocar});
  final _Destino destino;
  final bool activo;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: activo ? AppColors.superficieAzul2 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(destino.icono, color: activo ? AppColors.primario : AppColors.pizarra),
          title: Text(destino.titulo,
              style: TextStyle(fontWeight: activo ? FontWeight.w700 : FontWeight.w500, color: activo ? AppColors.primario : AppColors.marino)),
          onTap: () {
            alTocar?.call();
            context.go(destino.ruta);
          },
        ),
      ),
    );
  }
}

class _Campana extends StatelessWidget {
  const _Campana();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificacionesCubit, Recurso<BandejaNotificaciones>>(builder: (context, _) {
      final n = context.read<NotificacionesCubit>().noLeidas;
      return IconButton(
        tooltip: 'Notificaciones',
        onPressed: () => context.push('/notificaciones'),
        icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.notifications_none)),
      );
    });
  }
}
