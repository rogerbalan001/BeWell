import '../../../../core/estado/recurso.dart';
import '../../../resenas/domain/entities/resena.dart';
import '../../../resenas/domain/usecases/resenas_usecases.dart';
import '../../domain/entities/medico.dart';
import '../../domain/usecases/medicos_usecases.dart';

/// Directorio de especialistas verificados con filtros.
class DirectorioCubit extends RecursoCubit<List<Medico>> {
  DirectorioCubit(this._buscar, this._especialidadesUc);
  final BuscarEspecialistas _buscar;
  final ListarEspecialidades _especialidadesUc;

  String? especialidad;
  String? modalidad;
  String texto = '';
  List<String> especialidades = const [];

  Future<void> iniciar() async {
    try {
      especialidades = await _especialidadesUc();
    } catch (_) {
      especialidades = const [];
    }
    await buscar();
  }

  Future<void> buscar() => ejecutar(() => _buscar(especialidad: especialidad, texto: texto, modalidad: modalidad));

  void filtrar({String? especialidad, String? modalidad, bool limpiarEspecialidad = false, bool limpiarModalidad = false}) {
    if (limpiarEspecialidad) this.especialidad = null;
    if (limpiarModalidad) this.modalidad = null;
    if (especialidad != null) this.especialidad = especialidad;
    if (modalidad != null) this.modalidad = modalidad;
    buscar();
  }
}

class PerfilMedicoDatos {
  const PerfilMedicoDatos(this.medico, this.estadisticas, this.resenas);
  final Medico medico;
  final EstadisticasResenas estadisticas;
  final List<Resena> resenas;
}

class PerfilMedicoCubit extends RecursoCubit<PerfilMedicoDatos> {
  PerfilMedicoCubit(this._obtener, this._resenas);
  final ObtenerMedico _obtener;
  final ObtenerResenasMedico _resenas;

  Future<void> cargar(String id) => ejecutar(() async {
        final medico = await _obtener(id);
        final (estadisticas, resenas) = await _resenas(id);
        return PerfilMedicoDatos(medico, estadisticas, resenas);
      });
}

/// Panel del médico: su perfil completo (credenciales, horario, política).
class MiPerfilMedicoCubit extends RecursoCubit<Medico> {
  MiPerfilMedicoCubit(this._obtener);
  final ObtenerMiPerfilMedico _obtener;
  Future<void> cargar({bool silencioso = false}) => ejecutar(_obtener.call, silencioso: silencioso);
}

class VerificacionesCubit extends RecursoCubit<List<Medico>> {
  VerificacionesCubit(this._listar, this.revisar);
  final ListarVerificacionesPendientes _listar;
  final RevisarCredencial revisar;
  Future<void> cargar() => ejecutar(_listar.call, silencioso: true);
}
