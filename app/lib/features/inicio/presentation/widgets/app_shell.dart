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
        _Destino('/historia-clinica', Icons.medical_information_outlined, 'Historia clínica'),
        _Destino('/examenes', Icons.biotech_outlined, 'Exámenes'),
        _Destino('/recipes', Icons.receipt_long_outlined, 'Récipes'),
        _Destino('/emergencia', Icons.qr_code_2, 'Emergencia QR'),
        _Destino('/recordatorios', Icons.alarm_outlined, 'Recordatorios'),
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
///
/// El logo siempre lleva al inicio. Cuando la pantalla actual se abrió encima
/// de otra (detalle de una cita, un formulario…), la barra muestra «Atrás».
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.ubicacion});
  final Widget child;
  final String ubicacion;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionCubit>().state.usuario;
    final destinos = _destinos(usuario);
    final indice = destinos.lastIndexWhere((d) => ubicacion == d.ruta || ubicacion.startsWith('${d.ruta}/'));
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= 1100;
    // En las secciones del menú siempre se muestra el menú (☰ en móvil); «Atrás»
    // solo aparece en pantallas de detalle abiertas encima de otra.
    final esSeccion = destinos.any((d) => d.ruta == ubicacion);
    final puedeVolver = !esSeccion && GoRouter.of(context).canPop();
    final atras = IconButton(
      tooltip: 'Atrás',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => GoRouter.of(context).pop(),
    );

    final acciones = <Widget>[
      if (usuario?.esPaciente ?? false) Padding(padding: const EdgeInsets.only(right: 4), child: SelectorPerfil(compacto: ancho < 600)),
      const _Campana(),
      _MenuCuenta(usuario: usuario),
      SizedBox(width: escritorio ? 20 : 8),
    ];

    if (escritorio) {
      return Scaffold(
        body: Row(children: [
          Container(
            width: 264,
            decoration: const BoxDecoration(color: AppColors.superficie, border: Border(right: BorderSide(color: AppColors.borde))),
            child: SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Align(alignment: Alignment.centerLeft, child: BwLogo(tamano: 32)),
                ),
                Expanded(
                  child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                    for (var i = 0; i < destinos.length; i++) _ItemNav(destinos[i], activo: i == indice),
                  ]),
                ),
                const _SelloPrivacidad(),
              ]),
            ),
          ),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 64,
                automaticallyImplyLeading: false,
                leading: puedeVolver ? atras : null,
                titleSpacing: puedeVolver ? 0 : 28,
                title: Text(indice >= 0 ? destinos[indice].titulo : '', style: Theme.of(context).textTheme.titleMedium),
                actions: acciones,
              ),
              body: child,
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leading: puedeVolver ? atras : null,
        titleSpacing: 0,
        title: const BwLogo(tamano: 28),
        actions: acciones,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.superficie,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: BwLogo(
                  tamano: 30,
                  alPulsar: () {
                    Navigator.of(context).pop();
                    context.go('/');
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                for (var i = 0; i < destinos.length; i++)
                  _ItemNav(destinos[i], activo: i == indice, alTocar: () => Navigator.of(context).pop()),
              ]),
            ),
            const _SelloPrivacidad(),
          ]),
        ),
      ),
      body: child,
    );
  }
}

class _SelloPrivacidad extends StatelessWidget {
  const _SelloPrivacidad();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.verdeSuave.withAlpha(110), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.verdeOscuro),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Tus datos clínicos viajan y se guardan cifrados.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.verdeOscuro, height: 1.35)),
        ),
      ]),
    );
  }
}

class _MenuCuenta extends StatelessWidget {
  const _MenuCuenta({required this.usuario});
  final UsuarioSesion? usuario;

  @override
  Widget build(BuildContext context) {
    final nombre = usuario?.nombreMostrado ?? '';
    return PopupMenuButton<String>(
      tooltip: 'Tu cuenta',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: AvatarIniciales(nombre.isEmpty ? '?' : nombre, radio: 17),
      onSelected: (v) async {
        if (v == 'inicio') context.go('/inicio');
        if (v == 'salir') await context.read<SesionCubit>().cerrarSesion();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: Theme.of(context).textTheme.titleSmall),
            Text(usuario?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'inicio', child: Row(children: [Icon(Icons.home_outlined, size: 18), SizedBox(width: 10), Text('Ir al inicio')])),
        const PopupMenuItem(value: 'salir', child: Row(children: [Icon(Icons.logout, size: 18), SizedBox(width: 10), Text('Cerrar sesión')])),
      ],
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
    final color = activo ? AppColors.primarioOscuro : AppColors.pizarra;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: activo,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: AppColors.superficieAzul,
            splashFactory: NoSplash.splashFactory,
            onTap: () {
              alTocar?.call();
              context.go(destino.ruta);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo ? AppColors.superficieAzul2 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(destino.icono, size: 21, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(destino.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: activo ? AppColors.primarioOscuro : AppColors.marino,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                          )),
                ),
              ]),
            ),
          ),
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
