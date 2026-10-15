import '../entities/medico.dart';
import '../repositories/medicos_repository.dart';

/// Casos de uso del directorio, el panel del médico y la verificación profesional.
class BuscarEspecialistas {
  const BuscarEspecialistas(this._r);
  final MedicosRepository _r;
  Future<List<Medico>> call({String? especialidad, String? texto, String? modalidad}) =>
      _r.directorio(especialidad: especialidad, texto: texto, modalidad: modalidad);
}

class ListarEspecialidades {
  const ListarEspecialidades(this._r);
  final MedicosRepository _r;
  Future<List<String>> call() => _r.especialidades();
}

class ObtenerMedico {
  const ObtenerMedico(this._r);
  final MedicosRepository _r;
  Future<Medico> call(String id) => _r.obtener(id);
}

class ObtenerCatalogoPoliticas {
  const ObtenerCatalogoPoliticas(this._r);
  final MedicosRepository _r;
  Future<List<PoliticaCancelacion>> call() => _r.catalogoPoliticas();
}

class ObtenerMiPerfilMedico {
  const ObtenerMiPerfilMedico(this._r);
  final MedicosRepository _r;
  Future<Medico> call() => _r.miPerfil();
}

class ActualizarPerfilMedico {
  const ActualizarPerfilMedico(this._r);
  final MedicosRepository _r;
  Future<Medico> call({String? biografia, String? direccion, double? tarifa}) =>
      _r.actualizarPerfil(biografia: biografia, direccion: direccion, tarifa: tarifa);
}

class ConfigurarHorario {
  const ConfigurarHorario(this._r);
  final MedicosRepository _r;
  Future<void> call(List<BloqueHorario> bloques, List<String> modalidades) => _r.configurarHorario(bloques, modalidades);
}

class ConfigurarPoliticaCancelacion {
  const ConfigurarPoliticaCancelacion(this._r);
  final MedicosRepository _r;
  Future<void> call(String tipo) => _r.configurarPolitica(tipo);
}

class SubirCredencial {
  const SubirCredencial(this._r);
  final MedicosRepository _r;
  Future<void> call(String tipo, String numero, List<int> bytes, String nombreArchivo) =>
      _r.subirCredencial(tipo, numero, bytes, nombreArchivo);
}

class ListarVerificacionesPendientes {
  const ListarVerificacionesPendientes(this._r);
  final MedicosRepository _r;
  Future<List<Medico>> call() => _r.pendientesDeVerificacion();
}

class RevisarCredencial {
  const RevisarCredencial(this._r);
  final MedicosRepository _r;
  Future<void> aprobar(String medicoId, String credencialId) => _r.aprobarCredencial(medicoId, credencialId);
  Future<void> rechazar(String medicoId, String credencialId, String motivo) => _r.rechazarCredencial(medicoId, credencialId, motivo);
  Future<String> urlDocumento(String medicoId, String credencialId) => _r.urlCredencial(medicoId, credencialId);
}
