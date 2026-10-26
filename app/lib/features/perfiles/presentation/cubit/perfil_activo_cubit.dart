import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/usecases/perfiles_usecases.dart';

class PerfilesState extends Equatable {
  const PerfilesState({this.perfiles = const [], this.seleccionadoId, this.cargando = false, this.error});
  final List<Perfil> perfiles;
  final String? seleccionadoId;
  final bool cargando;
  final String? error;

  Perfil? get seleccionado {
    for (final p in perfiles) {
      if (p.id == seleccionadoId) return p;
    }
    return perfiles.isEmpty ? null : perfiles.first;
  }

  PerfilesState copyWith({List<Perfil>? perfiles, String? seleccionadoId, bool? cargando, String? error}) => PerfilesState(
        perfiles: perfiles ?? this.perfiles,
        seleccionadoId: seleccionadoId ?? this.seleccionadoId,
        cargando: cargando ?? this.cargando,
        error: error,
      );

  @override
  List<Object?> get props => [perfiles, seleccionadoId, cargando, error];
}

/// Perfil familiar activo: todas las pantallas del paciente trabajan sobre él
/// (HU: gestionar los perfiles de mis hijos o padres y cambiar entre ellos).
class PerfilActivoCubit extends Cubit<PerfilesState> {
  PerfilActivoCubit(this._listar, this._crear) : super(const PerfilesState());

  final ListarPerfiles _listar;
  final CrearPerfilFamiliar _crear;

  Future<void> cargar() async {
    emit(state.copyWith(cargando: true));
    try {
      final perfiles = await _listar();
      final actual = state.seleccionadoId;
      final sigue = perfiles.any((p) => p.id == actual);
      emit(state.copyWith(perfiles: perfiles, seleccionadoId: sigue ? actual : (perfiles.isEmpty ? null : perfiles.first.id), cargando: false));
    } on Failure catch (f) {
      emit(state.copyWith(cargando: false, error: f.mensaje));
    }
  }

  void seleccionar(String id) => emit(state.copyWith(seleccionadoId: id));

  Future<String?> crear(NuevoPerfil datos) async {
    try {
      final nuevo = await _crear(datos);
      emit(state.copyWith(perfiles: [...state.perfiles, nuevo]));
      return null;
    } on Failure catch (f) {
      return f.mensaje;
    }
  }

  void limpiar() => emit(const PerfilesState());
}
