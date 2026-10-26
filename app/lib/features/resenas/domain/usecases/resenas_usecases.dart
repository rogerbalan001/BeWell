import '../entities/resena.dart';
import '../repositories/resenas_repository.dart';

class ObtenerResenasMedico {
  const ObtenerResenasMedico(this._r);
  final ResenasRepository _r;
  Future<(EstadisticasResenas, List<Resena>)> call(String medicoId) => _r.deMedico(medicoId);
}

class ObtenerResenaDeCita {
  const ObtenerResenaDeCita(this._r);
  final ResenasRepository _r;
  Future<Resena?> call(String citaId) => _r.deCita(citaId);
}

/// HU: dejar reseñas solo de consultas realmente atendidas (la regla la valida el backend).
class PublicarResena {
  const PublicarResena(this._r);
  final ResenasRepository _r;
  Future<Resena> call(String citaId, Calificaciones c) => _r.publicar(citaId, c);
  Future<Resena> editar(String resenaId, Calificaciones c) => _r.editar(resenaId, c);
}
