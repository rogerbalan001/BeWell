import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/verificaciones_page.dart';
import '../../features/auth/presentation/cubit/sesion_cubit.dart';
import '../../features/auth/presentation/pages/acceso_page.dart';
import '../../features/citas/domain/entities/cita.dart';
import '../../features/citas/presentation/cubit/citas_cubits.dart';
import '../../features/citas/presentation/pages/cita_detalle_page.dart';
import '../../features/citas/presentation/pages/confirmacion_cita_page.dart';
import '../../features/citas/presentation/pages/mis_citas_page.dart';
import '../../features/citas/presentation/pages/seleccion_horario_page.dart';
import '../../features/emergencia/presentation/pages/ficha_emergencia_page.dart';
import '../../features/emergencia/presentation/pages/visor_emergencia_page.dart';
import '../../features/examenes/domain/entities/examen.dart';
import '../../features/examenes/presentation/pages/examenes_page.dart';
import '../../features/examenes/presentation/pages/revisar_resultados_page.dart';
import '../../features/examenes/presentation/pages/solicitar_examenes_page.dart';
import '../../features/examenes/presentation/pages/subir_examen_page.dart';
import '../../features/expediente/presentation/pages/expediente_page.dart';
import '../../features/expediente/presentation/pages/mis_pacientes_page.dart';
import '../../features/expediente/presentation/pages/permisos_page.dart';
import '../../features/expediente/presentation/pages/referencias_page.dart';
import '../../features/historia_clinica/presentation/pages/consulta_form_page.dart';
import '../../features/historia_clinica/presentation/pages/historia_clinica_page.dart';
import '../../features/inicio/presentation/pages/cargando_page.dart';
import '../../features/inicio/presentation/pages/inicio_page.dart';
import '../../features/inicio/presentation/pages/landing_page.dart';
import '../../features/inicio/presentation/widgets/app_shell.dart';
import '../../features/medicos/presentation/pages/credenciales_page.dart';
import '../../features/medicos/presentation/pages/directorio_page.dart';
import '../../features/medicos/presentation/pages/mi_agenda_page.dart';
import '../../features/medicos/presentation/pages/perfil_medico_page.dart';
import '../../features/notificaciones/presentation/notificaciones_page.dart';
import '../../features/perfiles/presentation/pages/perfiles_page.dart';
import '../../features/recipes/presentation/pages/emitir_recipe_page.dart';
import '../../features/recipes/presentation/pages/recipes_page.dart';
import '../../features/recipes/presentation/pages/verificar_recipe_page.dart';
import '../../features/recordatorios/presentation/pages/recordatorios_page.dart';

/// Convierte el stream del SesionCubit en un Listenable para go_router.
class _Refresco extends ChangeNotifier {
  _Refresco(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

bool _esPublica(String ruta) => ruta == '/' || ruta == '/acceso' || ruta.startsWith('/e/') || ruta.startsWith('/verificar');

GoRouter crearRouter(SesionCubit sesion) {
  String? pendiente;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _Refresco(sesion.stream),
    redirect: (context, state) {
      final ruta = state.matchedLocation;
      final estado = sesion.state.estado;

      if (estado == EstadoSesion.desconocida) {
        if (ruta != '/cargando') pendiente = state.uri.toString();
        return ruta == '/cargando' ? null : '/cargando';
      }
      if (ruta == '/cargando') {
        final destino = pendiente ?? '/';
        pendiente = null;
        if (estado == EstadoSesion.activa) return (destino == '/' || destino.startsWith('/acceso')) ? '/inicio' : destino;
        return _esPublica(Uri.parse(destino).path) ? destino : '/acceso?desde=${Uri.encodeComponent(destino)}';
      }
      if (estado == EstadoSesion.anonima && !_esPublica(ruta)) {
        return '/acceso?desde=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (estado == EstadoSesion.activa && (ruta == '/' || ruta == '/acceso')) {
        return state.uri.queryParameters['desde'] ?? '/inicio';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/cargando', builder: (_, __) => const CargandoPage()),
      GoRoute(path: '/', builder: (_, __) => const LandingPage()),
      GoRoute(path: '/acceso', builder: (_, s) => AccesoPage(registro: s.uri.queryParameters['registro'] == '1')),
      GoRoute(path: '/e/:token', builder: (_, s) => VisorEmergenciaPage(token: s.pathParameters['token']!)),
      GoRoute(path: '/verificar', builder: (_, __) => const VerificarRecipePage()),
      GoRoute(path: '/verificar/:codigo', builder: (_, s) => VerificarRecipePage(codigo: s.pathParameters['codigo'])),
      ShellRoute(
        builder: (_, s, child) => AppShell(ubicacion: s.uri.path, child: child),
        routes: [
          GoRoute(path: '/inicio', builder: (_, __) => const InicioPage()),
          GoRoute(path: '/notificaciones', builder: (_, __) => const NotificacionesPage()),
          GoRoute(path: '/recordatorios', builder: (_, __) => const RecordatoriosPage()),
          GoRoute(path: '/perfiles', builder: (_, __) => const PerfilesPage()),
          GoRoute(path: '/directorio', builder: (_, __) => const DirectorioPage()),
          GoRoute(path: '/medicos/:id', builder: (_, s) => PerfilMedicoPage(medicoId: s.pathParameters['id']!)),
          GoRoute(path: '/agendar/:medicoId', builder: (_, s) => SeleccionHorarioPage(medicoId: s.pathParameters['medicoId']!)),
          GoRoute(
            path: '/agendar/:medicoId/confirmar',
            builder: (_, s) => ConfirmacionCitaPage(borrador: s.extra is BorradorCita ? s.extra as BorradorCita : null),
          ),
          GoRoute(path: '/citas', builder: (_, __) => const MisCitasPage()),
          GoRoute(path: '/citas/:id', builder: (_, s) => CitaDetallePage(citaId: s.pathParameters['id']!)),
          GoRoute(
            path: '/citas/:id/recipe',
            builder: (_, s) => EmitirRecipePage(citaId: s.pathParameters['id']!, cita: s.extra is Cita ? s.extra as Cita : null),
          ),
          GoRoute(path: '/expediente', builder: (_, __) => const ExpedientePage()),
          GoRoute(path: '/expediente/permisos', builder: (_, __) => const PermisosPage()),
          GoRoute(path: '/historia-clinica', builder: (_, __) => const HistoriaClinicaPage()),
          GoRoute(path: '/referencias', builder: (_, __) => const ReferenciasPage()),
          GoRoute(path: '/examenes', builder: (_, __) => const ExamenesPage()),
          GoRoute(
            path: '/examenes/subir',
            builder: (_, s) => SubirExamenPage(solicitudId: s.uri.queryParameters['solicitudId'], tituloSugerido: s.uri.queryParameters['titulo']),
          ),
          GoRoute(path: '/examenes/:id/revisar', builder: (_, s) => RevisarResultadosPage(examen: s.extra is Examen ? s.extra as Examen : null)),
          GoRoute(path: '/recipes', builder: (_, __) => const RecipesPage()),
          GoRoute(path: '/emergencia', builder: (_, __) => const FichaEmergenciaPage()),
          GoRoute(path: '/medico/agenda', builder: (_, __) => const MiAgendaPage()),
          GoRoute(path: '/medico/credenciales', builder: (_, __) => const CredencialesPage()),
          GoRoute(path: '/medico/pacientes', builder: (_, __) => const MisPacientesPage()),
          GoRoute(path: '/medico/pacientes/:pacienteId', builder: (_, s) => ExpedientePage(pacienteId: s.pathParameters['pacienteId'])),
          GoRoute(
            path: '/medico/pacientes/:pacienteId/historia',
            builder: (_, s) => HistoriaClinicaPage(pacienteId: s.pathParameters['pacienteId']),
          ),
          GoRoute(
            path: '/medico/pacientes/:pacienteId/historia/consulta',
            builder: (_, s) => ConsultaFormPage(
              pacienteId: s.pathParameters['pacienteId']!,
              pacienteNombre: s.uri.queryParameters['nombre'],
              citaId: s.uri.queryParameters['citaId'],
            ),
          ),
          GoRoute(
            path: '/medico/examenes/solicitar',
            builder: (_, s) => SolicitarExamenesPage(
              pacienteId: s.uri.queryParameters['pacienteId'] ?? '',
              citaId: s.uri.queryParameters['citaId'],
              pacienteNombre: s.uri.queryParameters['nombre'],
            ),
          ),
          GoRoute(path: '/admin/verificaciones', builder: (_, __) => const VerificacionesPage()),
        ],
      ),
    ],
    errorBuilder: (_, s) => Scaffold(body: Center(child: Text('Página no encontrada: ${s.uri}'))),
  );
}
