import '../entities/disputa.dart';
import '../repositories/disputas_repository.dart';

/// HU de pagos: el administrador revisa las disputas y decide liberar o reembolsar.
class GestionarDisputas {
  const GestionarDisputas(this._r);
  final DisputasRepository _r;

  Future<List<Disputa>> listar() => _r.listar();
  Future<Disputa> resolver(String pagoId, AccionDisputa accion, {String? nota}) => _r.resolver(pagoId, accion, nota: nota);
}
