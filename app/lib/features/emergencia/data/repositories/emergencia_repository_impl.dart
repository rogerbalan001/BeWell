import '../../../../core/network/token_storage.dart';
import '../../domain/entities/ficha_emergencia.dart';
import '../../domain/repositories/emergencia_repository.dart';
import '../datasources/emergencia_remote_data_source.dart';

class EmergenciaRepositoryImpl implements EmergenciaRepository {
  const EmergenciaRepositoryImpl(this._r, this._almacen);
  final EmergenciaRemoteDataSource _r;
  final TokenStorage _almacen;

  @override
  Future<FichaEmergencia> obtener(String pacienteId) async => FichaMapper.ficha(await _r.obtener(pacienteId));

  @override
  Future<FichaEmergencia> guardar(String pacienteId, FichaEmergencia ficha) async => FichaMapper.ficha(await _r.guardar(pacienteId, ficha));

  @override
  Future<String> regenerarQr(String pacienteId) async {
    final url = (await _r.regenerar(pacienteId))['url'] as String;
    await _almacen.guardarTokenQr(pacienteId, url);
    return url;
  }

  @override
  Future<String?> urlQrGuardada(String pacienteId) => _almacen.leerTokenQr(pacienteId);

  @override
  Future<FichaEscaneada> escanear(String token) async => FichaMapper.escaneada(await _r.escanear(token));
}
