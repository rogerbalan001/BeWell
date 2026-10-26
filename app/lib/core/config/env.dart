import 'package:flutter/foundation.dart';

/// Configuración por entorno. Se puede sobrescribir con:
/// `flutter run --dart-define=API_URL=https://api.midominio.com/api/v1`
class Env {
  static const String _apiUrl = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    // El emulador de Android ve la máquina anfitriona como 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }
}
