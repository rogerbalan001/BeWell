import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../error/failure.dart';
import 'token_storage.dart';

/// Cliente HTTP único de la app (Core). Agrega el token JWT a cada solicitud,
/// renueva la sesión automáticamente ante un 401 y traduce errores a [Failure].
class ApiClient {
  ApiClient(this._tokens)
      : dio = Dio(BaseOptions(
          baseUrl: Env.apiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(_AuthInterceptor(dio, _tokens, () => _sesionExpirada.add(null)));
  }

  final Dio dio;
  final TokenStorage _tokens;
  final StreamController<void> _sesionExpirada = StreamController<void>.broadcast();

  /// Emite cuando el refresh token dejó de ser válido.
  Stream<void> get sesionExpirada => _sesionExpirada.stream;

  Future<dynamic> get(String ruta, {Map<String, dynamic>? query}) =>
      _ejecutar(() => dio.get<dynamic>(ruta, queryParameters: query));

  Future<dynamic> post(String ruta, {Object? data}) => _ejecutar(() => dio.post<dynamic>(ruta, data: data));

  Future<dynamic> put(String ruta, {Object? data}) => _ejecutar(() => dio.put<dynamic>(ruta, data: data));

  Future<dynamic> patch(String ruta, {Object? data}) => _ejecutar(() => dio.patch<dynamic>(ruta, data: data));

  Future<dynamic> delete(String ruta) => _ejecutar(() => dio.delete<dynamic>(ruta));

  Future<dynamic> _ejecutar(Future<Response<dynamic>> Function() solicitud) async {
    try {
      final respuesta = await solicitud();
      return respuesta.data;
    } on DioException catch (e) {
      throw mapearError(e);
    }
  }

  static Failure mapearError(DioException e) {
    final respuesta = e.response;
    if (respuesta == null) {
      return const Failure('No se pudo conectar con el servidor. Verifica tu conexión e inténtalo de nuevo.');
    }
    final data = respuesta.data;
    String? mensaje;
    String? codigo;
    if (data is Map) {
      final m = data['message'];
      mensaje = m is List ? m.join('\n') : m?.toString();
      codigo = data['codigo']?.toString();
    }
    return Failure(
      mensaje ?? 'Error inesperado (${respuesta.statusCode})',
      codigoHttp: respuesta.statusCode,
      codigo: codigo,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._tokens, this._alExpirar);

  final Dio _dio;
  final TokenStorage _tokens;
  final void Function() _alExpirar;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.leerAcceso();
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final opciones = err.requestOptions;
    final esAuth = opciones.path.contains('/auth/login') || opciones.path.contains('/auth/refresh');
    if (err.response?.statusCode != 401 || esAuth || opciones.extra['reintentado'] == true) {
      handler.next(err);
      return;
    }
    final refresh = await _tokens.leerRefresh();
    if (refresh == null) {
      handler.next(err);
      return;
    }
    try {
      final limpio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final r = await limpio.post<dynamic>('/auth/refresh', data: {'refreshToken': refresh});
      final datos = Map<String, dynamic>.from(r.data as Map);
      final nuevoAcceso = datos['accessToken'] as String;
      await _tokens.guardar(nuevoAcceso, datos['refreshToken'] as String);
      opciones.extra['reintentado'] = true;
      opciones.headers['Authorization'] = 'Bearer $nuevoAcceso';
      final reintento = await limpio.fetch<dynamic>(opciones);
      handler.resolve(reintento);
    } catch (_) {
      await _tokens.borrar();
      _alExpirar();
      handler.next(err);
    }
  }
}
