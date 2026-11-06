import 'package:flutter/material.dart';

/// Tokens de color de Bewell. El azul clínico (primario) es la marca y se reserva
/// para acciones e identidad; el resto de la interfaz vive en blancos y grises
/// fríos para que ese azul y los colores de estado se lean de un vistazo.
class AppColors {
  static const primario = Color(0xFF1A6BF0); // azul eléctrico: acciones principales
  static const primarioOscuro = Color(0xFF0053C5);
  static const marino = Color(0xFF0A2540); // tipografía fuerte y secciones oscuras
  static const marinoProfundo = Color(0xFF0B1F3A);
  static const verde = Color(0xFF10B981); // disponibilidad, confirmaciones, verificación
  static const verdeOscuro = Color(0xFF006746);
  static const pizarra = Color(0xFF475569); // texto de cuerpo
  static const pizarraClara = Color(0xFF64748B);
  static const lienzo = Color(0xFFF4F7FC); // fondo: blanco azulado, menos saturado que la marca
  static const superficie = Colors.white;
  static const superficieAzul = Color(0xFFEFF4FF);
  static const superficieAzul2 = Color(0xFFE5EEFF);
  static const borde = Color(0xFFE2E8F0);
  static const bordeFuerte = Color(0xFFCBD5E1); // contorno de botones secundarios y segmentos
  static const bordeAzul = Color(0x141A6BF0); // rgba(26,107,240,.08)
  static const error = Color(0xFFBA1A1A);
  static const errorSuave = Color(0xFFFFDAD6);
  static const ambar = Color(0xFFB45309);
  static const ambarSuave = Color(0xFFFEF3C7);
  static const verdeSuave = Color(0xFFD1FAE5);
  static const azulSuave = Color(0xFFDAE2FF);
  static const sombra = Color(0x140A2540); // rgba(10,37,64,.08)
}
