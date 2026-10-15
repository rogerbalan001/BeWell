/// Error de la capa de dominio. La capa de datos traduce las excepciones de
/// red (DioException) a [Failure] para que la presentación no dependa de Dio.
class Failure implements Exception {
  const Failure(this.mensaje, {this.codigoHttp, this.codigo});

  final String mensaje;
  final int? codigoHttp;
  final String? codigo;

  bool get noAutenticado => codigoHttp == 401;
  bool get noEncontrado => codigoHttp == 404;

  @override
  String toString() => mensaje;
}
