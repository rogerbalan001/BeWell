import 'package:equatable/equatable.dart';

/// Usuario autenticado. Los roles definen qué secciones ve en la app.
class UsuarioSesion extends Equatable {
  const UsuarioSesion({
    required this.id,
    required this.email,
    required this.roles,
    required this.nombreMostrado,
    this.medicoId,
  });

  final String id;
  final String email;
  final List<String> roles;
  final String nombreMostrado;
  final String? medicoId;

  bool get esPaciente => roles.contains('PACIENTE');
  bool get esMedico => roles.contains('MEDICO');
  bool get esAdmin => roles.contains('ADMIN');
  bool get esEmergencia => roles.contains('PERSONAL_EMERGENCIA');

  @override
  List<Object?> get props => [id, email, roles, nombreMostrado, medicoId];
}

class DatosRegistroPaciente {
  const DatosRegistroPaciente({
    required this.email,
    required this.password,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.sexo,
    this.cedula,
    this.telefono,
  });
  final String email, password, nombres, apellidos, sexo;
  final DateTime fechaNacimiento;
  final String? cedula, telefono;
}

class DatosRegistroMedico {
  const DatosRegistroMedico({
    required this.email,
    required this.password,
    required this.nombres,
    required this.apellidos,
    required this.especialidad,
    required this.tarifaConsulta,
    this.telefono,
  });
  final String email, password, nombres, apellidos, especialidad;
  final double tarifaConsulta;
  final String? telefono;
}
