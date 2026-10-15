import '../../../../core/utils/json.dart';
import '../../domain/entities/resena.dart';
import '../../domain/repositories/resenas_repository.dart';
import '../datasources/resenas_remote_data_source.dart';

class ResenasRepositoryImpl implements ResenasRepository {
  const ResenasRepositoryImpl(this._r);
  final ResenasRemoteDataSource _r;

  @override
  Future<(EstadisticasResenas, List<Resena>)> deMedico(String medicoId) async {
    final j = await _r.deMedico(medicoId);
    return (ResenaMapper.estadisticas(mapa(j['estadisticas'])), listaDeMapas(j['resenas']).map(ResenaMapper.desdeJson).toList());
  }

  @override
  Future<Resena?> deCita(String citaId) async {
    final j = await _r.deCita(citaId);
    return j == null ? null : ResenaMapper.desdeJson(j);
  }

  @override
  Future<Resena> publicar(String citaId, Calificaciones c) async => ResenaMapper.desdeJson(await _r.publicar(citaId, c));

  @override
  Future<Resena> editar(String resenaId, Calificaciones c) async => ResenaMapper.desdeJson(await _r.editar(resenaId, c));
}
