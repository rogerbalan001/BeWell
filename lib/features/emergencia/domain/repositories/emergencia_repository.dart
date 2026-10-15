import '../entities/ficha_emergencia.dart';

abstract class EmergenciaRepository {
  Future<FichaEmergencia> obtener(String pacienteId);
  Future<FichaEmergencia> guardar(String pacienteId, FichaEmergencia ficha);
  /// Genera un QR nuevo (invalida el anterior) y devuelve la URL pública.
  Future<String> regenerarQr(String pacienteId);
  /// URL del QR vigente guardada en el dispositivo (el servidor solo guarda su hash).
  Future<String?> urlQrGuardada(String pacienteId);
  Future<FichaEscaneada> escanear(String token);
}
