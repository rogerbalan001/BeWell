import '../entities/resena.dart';

abstract class ResenasRepository {
  Future<(EstadisticasResenas, List<Resena>)> deMedico(String medicoId);
  Future<Resena?> deCita(String citaId);
  Future<Resena> publicar(String citaId, Calificaciones c);
  Future<Resena> editar(String resenaId, Calificaciones c);
}
