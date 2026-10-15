import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/perfil.dart';

class PerfilesRemoteDataSource {
  const PerfilesRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listar() async => listaDeMapas(await _api.get('/perfiles'));

  Future<Map<String, dynamic>> crear(NuevoPerfil d) async => mapa(await _api.post('/perfiles', data: {
        'nombres': d.nombres,
        'apellidos': d.apellidos,
        'parentescoConTitular': d.parentesco,
        'fechaNacimiento': Formatos.soloFecha(d.fechaNacimiento),
        'sexo': d.sexo,
        if (d.cedula != null && d.cedula!.isNotEmpty) 'cedula': d.cedula,
      }));
}

/// Mapper JSON → entidad (DTO de la capa de datos).
class PerfilMapper {
  static Perfil desdeJson(Map<String, dynamic> j) => Perfil(
        id: j['id'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        parentesco: j['parentescoConTitular'] as String,
        esTitular: j['esTitular'] as bool? ?? false,
        fechaNacimiento: DateTime.parse(j['fechaNacimiento'] as String),
        edad: (j['edad'] as num?)?.toInt() ?? 0,
        sexo: j['sexo'] as String,
        cedula: textoOpcional(j['cedula']),
      );
}
