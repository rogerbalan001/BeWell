import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/usuario_sesion.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoto, this._tokens, this._api);

  final AuthRemoteDataSource _remoto;
  final TokenStorage _tokens;
  final ApiClient _api;

  @override
  Stream<void> get sesionExpirada => _api.sesionExpirada;

  @override
  Future<UsuarioSesion> iniciarSesion(String email, String password) async => _guardarSesion(await _remoto.login(email, password));

  @override
  Future<UsuarioSesion> registrarPaciente(DatosRegistroPaciente datos) async => _guardarSesion(await _remoto.registrarPaciente(datos));

  @override
  Future<UsuarioSesion> registrarMedico(DatosRegistroMedico datos) async => _guardarSesion(await _remoto.registrarMedico(datos));

  @override
  Future<UsuarioSesion?> restaurarSesion() async {
    final refresh = await _tokens.leerRefresh();
    if (refresh == null) return null;
    try {
      return await _guardarSesion(await _remoto.refrescar(refresh));
    } on Failure catch (f) {
      if (f.noAutenticado) await _tokens.borrar();
      return null;
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _remoto.logout();
    } on Failure {
      // Aunque falle en el servidor, la sesión local se elimina.
    }
    await _tokens.borrar();
  }

  Future<UsuarioSesion> _guardarSesion(Map<String, dynamic> json) async {
    await _tokens.guardar(json['accessToken'] as String, json['refreshToken'] as String);
    final u = mapa(json['usuario']);
    return UsuarioSesion(
      id: u['id'] as String,
      email: u['email'] as String,
      roles: textos(u['roles']),
      nombreMostrado: u['nombreMostrado'] as String,
      medicoId: textoOpcional(u['medicoId']),
    );
  }
}
