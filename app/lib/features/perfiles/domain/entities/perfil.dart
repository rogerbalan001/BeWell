import 'package:equatable/equatable.dart';

/// Perfil de paciente: el titular y sus dependientes (hijos, padres…).
class Perfil extends Equatable {
  const Perfil({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.parentesco,
    required this.esTitular,
    required this.fechaNacimiento,
    required this.edad,
    required this.sexo,
    this.cedula,
    this.mayorDeEdad = false,
    this.solicitudControlPendiente = false,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String parentesco;
  final bool esTitular;
  final DateTime fechaNacimiento;
  final int edad;
  final String sexo;
  final String? cedula;

  /// Tiene 18 años o más.
  final bool mayorDeEdad;

  /// El propio dependiente, ya mayor de edad, pidió gestionar su perfil desde su cuenta.
  final bool solicitudControlPendiente;

  /// Dependiente que ya puede tomar el control de su perfil.
  bool get puedeIndependizarse => !esTitular && mayorDeEdad;

  String get nombreCompleto => '$nombres $apellidos';
  String get etiqueta => esTitular ? 'Yo' : _capitalizar(parentesco);

  static String _capitalizar(String s) => s.isEmpty ? s : s[0] + s.substring(1).toLowerCase();

  @override
  List<Object?> get props => [id, nombres, apellidos, parentesco, cedula, fechaNacimiento, mayorDeEdad, solicitudControlPendiente];
}

class NuevoPerfil {
  const NuevoPerfil({
    required this.nombres,
    required this.apellidos,
    required this.parentesco,
    required this.fechaNacimiento,
    required this.sexo,
    this.cedula,
  });
  final String nombres, apellidos, parentesco, sexo;
  final DateTime fechaNacimiento;
  final String? cedula;
}
