import '../../domain/entities/disputa.dart';
import '../../domain/repositories/disputas_repository.dart';
import '../datasources/disputas_remote_data_source.dart';

class DisputasRepositoryImpl implements DisputasRepository {
  const DisputasRepositoryImpl(this._r);
  final DisputasRemoteDataSource _r;

  @override
  Future<List<Disputa>> listar() async => (await _r.listar()).map(DisputaMapper.desdeJson).toList();

  @override
  Future<Disputa> resolver(String pagoId, AccionDisputa accion, {String? nota}) async =>
      DisputaMapper.desdeJson(await _r.resolver(pagoId, accion, nota));
}
