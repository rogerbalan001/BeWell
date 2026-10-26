import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro (Keychain / Keystore / WebCrypto) de credenciales.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _acceso = 'bewell.accessToken';
  static const _refresh = 'bewell.refreshToken';
  static const _prefijoQr = 'bewell.qr.';

  Future<void> guardar(String accessToken, String refreshToken) async {
    await _storage.write(key: _acceso, value: accessToken);
    await _storage.write(key: _refresh, value: refreshToken);
  }

  Future<String?> leerAcceso() => _storage.read(key: _acceso);
  Future<String?> leerRefresh() => _storage.read(key: _refresh);

  Future<void> borrar() async {
    await _storage.delete(key: _acceso);
    await _storage.delete(key: _refresh);
  }

  /// El servidor solo guarda el hash del token del QR: la app conserva el token.
  Future<void> guardarTokenQr(String pacienteId, String token) =>
      _storage.write(key: '$_prefijoQr$pacienteId', value: token);

  Future<String?> leerTokenQr(String pacienteId) => _storage.read(key: '$_prefijoQr$pacienteId');
}
