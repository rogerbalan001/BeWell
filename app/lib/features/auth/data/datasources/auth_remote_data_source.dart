import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/usuario_sesion.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> login(String email, String password) async =>
      mapa(await _api.post('/auth/login', data: {'email': email, 'password': password}));

  Future<Map<String, dynamic>> refrescar(String refreshToken) async =>
      mapa(await _api.post('/auth/refresh', data: {'refreshToken': refreshToken}));

  Future<Map<String, dynamic>> registrarPaciente(DatosRegistroPaciente d) async => mapa(await _api.post(
        '/auth/registro/paciente',
        data: {
          'email': d.email,
          'password': d.password,
          'nombres': d.nombres,
          'apellidos': d.apellidos,
          'fechaNacimiento': Formatos.soloFecha(d.fechaNacimiento),
          'sexo': d.sexo,
          if (d.cedula != null && d.cedula!.isNotEmpty) 'cedula': d.cedula,
          if (d.telefono != null && d.telefono!.isNotEmpty) 'telefono': d.telefono,
        },
      ));

  Future<Map<String, dynamic>> registrarMedico(DatosRegistroMedico d) async => mapa(await _api.post(
        '/auth/registro/medico',
        data: {
          'email': d.email,
          'password': d.password,
          'nombres': d.nombres,
          'apellidos': d.apellidos,
          'especialidades': [d.especialidad],
          'tarifaConsulta': d.tarifaConsulta,
          if (d.telefono != null && d.telefono!.isNotEmpty) 'telefono': d.telefono,
        },
      ));

  Future<void> logout() async => _api.post('/auth/logout');
}
