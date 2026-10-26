import 'package:equatable/equatable.dart';

const camposFicha = <String, String>{
  'grupoSanguineo': 'Grupo sanguíneo',
  'alergias': 'Alergias',
  'condicionesCronicas': 'Condiciones críticas',
  'medicacionActual': 'Medicación actual',
  'contactos': 'Contactos de emergencia',
};

const gruposSanguineos = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

class ContactoEmergencia extends Equatable {
  const ContactoEmergencia({required this.nombre, required this.parentesco, required this.telefono});
  final String nombre, parentesco, telefono;
  Map<String, dynamic> aJson() => {'nombre': nombre, 'parentesco': parentesco, 'telefono': telefono};
  @override
  List<Object?> get props => [nombre, telefono];
}

class FichaEmergencia extends Equatable {
  const FichaEmergencia({
    this.grupoSanguineo,
    this.alergias = const [],
    this.condicionesCronicas = const [],
    this.medicacionActual = const [],
    this.contactos = const [],
    this.camposPublicos = const ['grupoSanguineo', 'alergias', 'condicionesCronicas', 'contactos'],
    this.tieneQr = false,
    this.qrGeneradoEn,
  });
  final String? grupoSanguineo;
  final List<String> alergias, condicionesCronicas, medicacionActual, camposPublicos;
  final List<ContactoEmergencia> contactos;
  final bool tieneQr;
  final DateTime? qrGeneradoEn;

  @override
  List<Object?> get props => [grupoSanguineo, alergias, condicionesCronicas, medicacionActual, contactos, camposPublicos, tieneQr];
}

/// Lo que ve quien escanea el QR (sin el resto del expediente).
class FichaEscaneada {
  const FichaEscaneada({required this.nombre, required this.edad, required this.sexo, required this.nivel, required this.ficha});
  final String nombre;
  final int edad;
  final String sexo;
  final String nivel;
  final FichaEmergencia ficha;
  bool get ampliada => nivel == 'AMPLIADO';
}
