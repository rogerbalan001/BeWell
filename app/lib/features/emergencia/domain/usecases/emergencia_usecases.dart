import '../entities/ficha_emergencia.dart';
import '../repositories/emergencia_repository.dart';

class GestionarFichaEmergencia {
  const GestionarFichaEmergencia(this._r);
  final EmergenciaRepository _r;
  Future<FichaEmergencia> obtener(String pacienteId) => _r.obtener(pacienteId);
  Future<FichaEmergencia> guardar(String pacienteId, FichaEmergencia f) => _r.guardar(pacienteId, f);
  Future<String?> urlQr(String pacienteId) => _r.urlQrGuardada(pacienteId);
  /// HU: el paciente puede regenerar el QR para invalidar el anterior.
  Future<String> regenerarQr(String pacienteId) => _r.regenerarQr(pacienteId);
}

/// HU personal de emergencias: escanear el QR sin iniciar sesión.
class LeerFichaPorQr {
  const LeerFichaPorQr(this._r);
  final EmergenciaRepository _r;
  Future<FichaEscaneada> call(String token) => _r.escanear(token);
}
