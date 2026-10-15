import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/sesion_cubit.dart';
import 'features/notificaciones/presentation/notificaciones_cubit.dart';
import 'features/perfiles/presentation/cubit/perfil_activo_cubit.dart';

class BewellApp extends StatefulWidget {
  const BewellApp({super.key});

  @override
  State<BewellApp> createState() => _BewellAppState();
}

class _BewellAppState extends State<BewellApp> {
  late final SesionCubit _sesion = sl<SesionCubit>();
  late final GoRouter _router = crearRouter(_sesion);

  @override
  void initState() {
    super.initState();
    _sesion.restaurar();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _sesion),
        BlocProvider.value(value: sl<PerfilActivoCubit>()),
        BlocProvider.value(value: sl<NotificacionesCubit>()),
      ],
      child: BlocListener<SesionCubit, SesionState>(
        listenWhen: (a, b) => a.usuario?.id != b.usuario?.id,
        listener: (context, s) {
          final perfiles = context.read<PerfilActivoCubit>();
          final notificaciones = context.read<NotificacionesCubit>();
          if (s.usuario == null) {
            perfiles.limpiar();
            notificaciones.detener();
            return;
          }
          if (s.usuario!.esPaciente) perfiles.cargar();
          notificaciones.iniciar();
        },
        child: MaterialApp.router(
          title: 'Bewell — Salud digital',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
