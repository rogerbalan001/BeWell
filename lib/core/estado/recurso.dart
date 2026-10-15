import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/failure.dart';

/// Estado genérico de un recurso remoto que maneja la capa de presentación.
sealed class Recurso<T> extends Equatable {
  const Recurso();

  T? get datosOpcional => switch (this) {
        RecursoListo<T>(:final datos) => datos,
        _ => null,
      };

  @override
  List<Object?> get props => [];
}

class RecursoInicial<T> extends Recurso<T> {
  const RecursoInicial();
}

class RecursoCargando<T> extends Recurso<T> {
  const RecursoCargando();
}

class RecursoListo<T> extends Recurso<T> {
  const RecursoListo(this.datos, {this.version = 0});
  final T datos;
  final int version;
  @override
  List<Object?> get props => [datos, version];
}

class RecursoError<T> extends Recurso<T> {
  const RecursoError(this.mensaje);
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}

/// Cubit base que ejecuta un caso de uso y publica Cargando → Listo / Error.
abstract class RecursoCubit<T> extends Cubit<Recurso<T>> {
  RecursoCubit() : super(RecursoInicial<T>());

  int _version = 0;

  Future<void> ejecutar(Future<T> Function() casoDeUso, {bool silencioso = false}) async {
    if (!silencioso || state is! RecursoListo<T>) emit(RecursoCargando<T>());
    try {
      final datos = await casoDeUso();
      if (!isClosed) emit(RecursoListo<T>(datos, version: ++_version));
    } on Failure catch (f) {
      if (!isClosed) emit(RecursoError<T>(f.mensaje));
    } catch (e) {
      if (!isClosed) emit(RecursoError<T>('Ocurrió un error inesperado: $e'));
    }
  }
}

/// Ejecuta una acción y devuelve el mensaje de error (o null si salió bien).
Future<String?> intentar(Future<void> Function() accion) async {
  try {
    await accion();
    return null;
  } on Failure catch (f) {
    return f.mensaje;
  } catch (e) {
    return 'Ocurrió un error inesperado: $e';
  }
}
