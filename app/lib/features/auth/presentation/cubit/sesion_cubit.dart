import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/usuario_sesion.dart';
import '../../domain/usecases/auth_usecases.dart';

enum EstadoSesion { desconocida, anonima, activa }

class SesionState extends Equatable {
  const SesionState(this.estado, [this.usuario]);
  final EstadoSesion estado;
  final UsuarioSesion? usuario;
  @override
  List<Object?> get props => [estado, usuario];
}

/// Estado global de la sesión. El router lo escucha para proteger rutas.
class SesionCubit extends Cubit<SesionState> {
  SesionCubit({
    required IniciarSesion iniciarSesion,
    required RegistrarPaciente registrarPaciente,
    required RegistrarMedico registrarMedico,
    required RestaurarSesion restaurarSesion,
    required CerrarSesion cerrarSesion,
    required Stream<void> sesionExpirada,
  })  : _iniciar = iniciarSesion,
        _registrarPaciente = registrarPaciente,
        _registrarMedico = registrarMedico,
        _restaurar = restaurarSesion,
        _cerrar = cerrarSesion,
        super(const SesionState(EstadoSesion.desconocida)) {
    _suscripcion = sesionExpirada.listen((_) => emit(const SesionState(EstadoSesion.anonima)));
  }

  final IniciarSesion _iniciar;
  final RegistrarPaciente _registrarPaciente;
  final RegistrarMedico _registrarMedico;
  final RestaurarSesion _restaurar;
  final CerrarSesion _cerrar;
  late final StreamSubscription<void> _suscripcion;

  UsuarioSesion? get usuario => state.usuario;

  Future<void> restaurar() async {
    final u = await _restaurar();
    emit(u == null ? const SesionState(EstadoSesion.anonima) : SesionState(EstadoSesion.activa, u));
  }

  Future<String?> iniciarSesion(String email, String password) => _accion(() => _iniciar(email, password));

  Future<String?> registrarPaciente(DatosRegistroPaciente d) => _accion(() => _registrarPaciente(d));

  Future<String?> registrarMedico(DatosRegistroMedico d) => _accion(() => _registrarMedico(d));

  Future<void> cerrarSesion() async {
    await _cerrar();
    emit(const SesionState(EstadoSesion.anonima));
  }

  Future<String?> _accion(Future<UsuarioSesion> Function() fn) async {
    try {
      emit(SesionState(EstadoSesion.activa, await fn()));
      return null;
    } on Failure catch (f) {
      return f.mensaje;
    }
  }

  @override
  Future<void> close() {
    _suscripcion.cancel();
    return super.close();
  }
}
