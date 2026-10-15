import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/sesion_cubit.dart';
import '../../features/citas/data/datasources/citas_remote_data_source.dart';
import '../../features/citas/data/repositories/citas_repository_impl.dart';
import '../../features/citas/domain/repositories/citas_repository.dart';
import '../../features/citas/domain/usecases/citas_usecases.dart';
import '../../features/citas/presentation/cubit/citas_cubits.dart';
import '../../features/emergencia/data/datasources/emergencia_remote_data_source.dart';
import '../../features/emergencia/data/repositories/emergencia_repository_impl.dart';
import '../../features/emergencia/domain/repositories/emergencia_repository.dart';
import '../../features/emergencia/domain/usecases/emergencia_usecases.dart';
import '../../features/examenes/data/datasources/examenes_remote_data_source.dart';
import '../../features/examenes/data/repositories/examenes_repository_impl.dart';
import '../../features/examenes/domain/repositories/examenes_repository.dart';
import '../../features/examenes/domain/usecases/examenes_usecases.dart';
import '../../features/examenes/presentation/cubit/examenes_cubit.dart';
import '../../features/expediente/data/datasources/expediente_remote_data_source.dart';
import '../../features/expediente/data/repositories/expediente_repository_impl.dart';
import '../../features/expediente/domain/repositories/expediente_repository.dart';
import '../../features/expediente/domain/usecases/expediente_usecases.dart';
import '../../features/expediente/presentation/cubit/expediente_cubits.dart';
import '../../features/medicos/data/datasources/medicos_remote_data_source.dart';
import '../../features/medicos/data/repositories/medicos_repository_impl.dart';
import '../../features/medicos/domain/repositories/medicos_repository.dart';
import '../../features/medicos/domain/usecases/medicos_usecases.dart';
import '../../features/medicos/presentation/cubit/medicos_cubits.dart';
import '../../features/notificaciones/data/notificaciones_repository_impl.dart';
import '../../features/notificaciones/domain/notificaciones.dart';
import '../../features/notificaciones/presentation/notificaciones_cubit.dart';
import '../../features/perfiles/data/datasources/perfiles_remote_data_source.dart';
import '../../features/perfiles/data/repositories/perfiles_repository_impl.dart';
import '../../features/perfiles/domain/repositories/perfiles_repository.dart';
import '../../features/perfiles/domain/usecases/perfiles_usecases.dart';
import '../../features/perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../features/recipes/data/datasources/recipes_remote_data_source.dart';
import '../../features/recipes/data/repositories/recipes_repository_impl.dart';
import '../../features/recipes/domain/repositories/recipes_repository.dart';
import '../../features/recipes/domain/usecases/recipes_usecases.dart';
import '../../features/recipes/presentation/cubit/recipes_cubit.dart';
import '../../features/resenas/data/datasources/resenas_remote_data_source.dart';
import '../../features/resenas/data/repositories/resenas_repository_impl.dart';
import '../../features/resenas/domain/repositories/resenas_repository.dart';
import '../../features/resenas/domain/usecases/resenas_usecases.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';

/// Contenedor de inyección de dependencias (get_it). Es la raíz de
/// composición: conecta Presentación → Dominio ← Datos.
final GetIt sl = GetIt.instance;

void configurarDependencias() {
  // ---------- Core ----------
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage(const FlutterSecureStorage()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // ---------- Auth ----------
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl(), sl()));
  sl.registerLazySingleton(() => IniciarSesion(sl()));
  sl.registerLazySingleton(() => RegistrarPaciente(sl()));
  sl.registerLazySingleton(() => RegistrarMedico(sl()));
  sl.registerLazySingleton(() => RestaurarSesion(sl()));
  sl.registerLazySingleton(() => CerrarSesion(sl()));
  sl.registerLazySingleton(() => SesionCubit(
        iniciarSesion: sl(),
        registrarPaciente: sl(),
        registrarMedico: sl(),
        restaurarSesion: sl(),
        cerrarSesion: sl(),
        sesionExpirada: sl<AuthRepository>().sesionExpirada,
      ));

  // ---------- Perfiles familiares ----------
  sl.registerLazySingleton(() => PerfilesRemoteDataSource(sl()));
  sl.registerLazySingleton<PerfilesRepository>(() => PerfilesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ListarPerfiles(sl()));
  sl.registerLazySingleton(() => CrearPerfilFamiliar(sl()));
  sl.registerLazySingleton(() => PerfilActivoCubit(sl(), sl()));

  // ---------- Médicos, agenda y verificación ----------
  sl.registerLazySingleton(() => MedicosRemoteDataSource(sl()));
  sl.registerLazySingleton<MedicosRepository>(() => MedicosRepositoryImpl(sl()));
  sl.registerLazySingleton(() => BuscarEspecialistas(sl()));
  sl.registerLazySingleton(() => ListarEspecialidades(sl()));
  sl.registerLazySingleton(() => ObtenerMedico(sl()));
  sl.registerLazySingleton(() => ObtenerCatalogoPoliticas(sl()));
  sl.registerLazySingleton(() => ObtenerMiPerfilMedico(sl()));
  sl.registerLazySingleton(() => ActualizarPerfilMedico(sl()));
  sl.registerLazySingleton(() => ConfigurarHorario(sl()));
  sl.registerLazySingleton(() => ConfigurarPoliticaCancelacion(sl()));
  sl.registerLazySingleton(() => SubirCredencial(sl()));
  sl.registerLazySingleton(() => ListarVerificacionesPendientes(sl()));
  sl.registerLazySingleton(() => RevisarCredencial(sl()));
  sl.registerFactory(() => DirectorioCubit(sl(), sl()));
  sl.registerFactory(() => PerfilMedicoCubit(sl(), sl()));
  sl.registerFactory(() => MiPerfilMedicoCubit(sl()));
  sl.registerFactory(() => VerificacionesCubit(sl(), sl()));

  // ---------- Reseñas ----------
  sl.registerLazySingleton(() => ResenasRemoteDataSource(sl()));
  sl.registerLazySingleton<ResenasRepository>(() => ResenasRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ObtenerResenasMedico(sl()));
  sl.registerLazySingleton(() => ObtenerResenaDeCita(sl()));
  sl.registerLazySingleton(() => PublicarResena(sl()));

  // ---------- Citas y pagos ----------
  sl.registerLazySingleton(() => CitasRemoteDataSource(sl()));
  sl.registerLazySingleton<CitasRepository>(() => CitasRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ConsultarDisponibilidad(sl()));
  sl.registerLazySingleton(() => AgendarCita(sl()));
  sl.registerLazySingleton(() => ListarCitas(sl()));
  sl.registerLazySingleton(() => ObtenerCita(sl()));
  sl.registerLazySingleton(() => CancelarCita(sl()));
  sl.registerLazySingleton(() => MarcarCitaAtendida(sl()));
  sl.registerLazySingleton(() => ReportarProblemaPago(sl()));
  sl.registerLazySingleton(() => ProponerSeguimiento(sl()));
  sl.registerLazySingleton(() => ResponderPropuesta(sl()));
  sl.registerFactory(() => HorarioCubit(sl(), sl()));
  sl.registerFactory(() => MisCitasCubit(sl()));
  sl.registerFactory(() => CitaDetalleCubit(sl()));

  // ---------- Expediente, permisos y referencias ----------
  sl.registerLazySingleton(() => ExpedienteRemoteDataSource(sl()));
  sl.registerLazySingleton<ExpedienteRepository>(() => ExpedienteRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ObtenerExpediente(sl()));
  sl.registerLazySingleton(() => ObtenerLineaDeTiempo(sl()));
  sl.registerLazySingleton(() => AgregarInformacionClinica(sl()));
  sl.registerLazySingleton(() => GestionarPermisos(sl()));
  sl.registerLazySingleton(() => ListarMisPacientes(sl()));
  sl.registerLazySingleton(() => GestionarReferencias(sl()));
  sl.registerFactory(() => ExpedienteCubit(sl(), sl()));
  sl.registerFactory(() => PermisosCubit(sl()));
  sl.registerFactory(() => ReferenciasCubit(sl()));
  sl.registerFactory(() => MisPacientesCubit(sl()));

  // ---------- Exámenes ----------
  sl.registerLazySingleton(() => ExamenesRemoteDataSource(sl()));
  sl.registerLazySingleton<ExamenesRepository>(() => ExamenesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ListarExamenes(sl()));
  sl.registerLazySingleton(() => SubirExamen(sl()));
  sl.registerLazySingleton(() => ConfirmarResultados(sl()));
  sl.registerLazySingleton(() => SolicitarExamenes(sl()));
  sl.registerFactory(() => ExamenesCubit(sl()));

  // ---------- Récipes ----------
  sl.registerLazySingleton(() => RecipesRemoteDataSource(sl()));
  sl.registerLazySingleton<RecipesRepository>(() => RecipesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ListarRecipes(sl()));
  sl.registerLazySingleton(() => EmitirRecipe(sl()));
  sl.registerLazySingleton(() => VerificarRecipe(sl()));
  sl.registerFactory(() => RecipesCubit(sl()));

  // ---------- Emergencias ----------
  sl.registerLazySingleton(() => EmergenciaRemoteDataSource(sl()));
  sl.registerLazySingleton<EmergenciaRepository>(() => EmergenciaRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton(() => GestionarFichaEmergencia(sl()));
  sl.registerLazySingleton(() => LeerFichaPorQr(sl()));

  // ---------- Notificaciones ----------
  sl.registerLazySingleton<NotificacionesRepository>(() => NotificacionesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => ConsultarNotificaciones(sl()));
  sl.registerLazySingleton(() => NotificacionesCubit(sl()));
}
