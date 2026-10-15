import 'package:intl/intl.dart';

/// Formatos de fecha, hora y dinero en español.
class Formatos {
  static String fechaLarga(DateTime f) => _capitalizar(DateFormat("EEEE d 'de' MMMM", 'es').format(f));
  static String fechaCorta(DateTime f) => DateFormat('d MMM yyyy', 'es').format(f);
  static String fechaHora(DateTime f) => DateFormat("d MMM yyyy, h:mm a", 'es').format(f);
  static String hora(DateTime f) => DateFormat('h:mm a', 'es').format(f);
  static String diaSemanaCorto(DateTime f) => DateFormat('EEE', 'es').format(f).toUpperCase().replaceAll('.', '');
  static String mesAnio(DateTime f) => _capitalizar(DateFormat('MMMM yyyy', 'es').format(f));
  static String dinero(double monto, [String moneda = 'USD']) => '\$${monto.toStringAsFixed(2)} $moneda';
  static String iso(DateTime f) => f.toUtc().toIso8601String();
  static String soloFecha(DateTime f) => DateFormat('yyyy-MM-dd').format(f);

  static String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length > 1 ? partes[1][0] : '')).toUpperCase();
  }

  static String relativo(DateTime f) {
    final d = DateTime.now().difference(f);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays < 7) return 'hace ${d.inDays} d';
    return fechaCorta(f);
  }
}
