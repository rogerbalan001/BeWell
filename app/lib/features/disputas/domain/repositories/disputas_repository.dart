import '../entities/disputa.dart';

abstract class DisputasRepository {
  /// Disputas abiertas, de la más antigua a la más reciente.
  Future<List<Disputa>> listar();

  /// Resuelve la disputa y devuelve el pago con su nuevo estado.
  Future<Disputa> resolver(String pagoId, AccionDisputa accion, {String? nota});
}
