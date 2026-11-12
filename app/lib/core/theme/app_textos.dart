import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos de texto de Bewell. Usa estos en lugar de escribir un `TextStyle` en cada
/// pantalla: así reserva, expediente, exámenes y récipes se leen igual. La familia
/// (Plus Jakarta Sans) y el color base vienen del tema; aquí solo se fija la jerarquía.
/// Son constantes, así que sirven dentro de widgets `const`.
class AppTextos {
  AppTextos._();

  /// Título de una hoja de detalle o de un documento (22, extra negrita).
  static const tituloDetalle = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3);

  /// Título de una sección o de un bloque destacado (18, extra negrita).
  static const tituloSeccion = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);

  /// Título de una tarjeta: nombre del médico, del examen, de la cita (17, negrita).
  static const tituloTarjeta = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);

  /// Texto resaltado dentro de un párrafo o de una fila.
  static const enfasis = TextStyle(fontWeight: FontWeight.w700);

  /// Resalte suave (etiquetas de campos, nombres en una lista).
  static const enfasisSuave = TextStyle(fontWeight: FontWeight.w600);

  /// Resalte en tamaño pequeño.
  static const enfasisPequeno = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  /// Texto pequeño con el color de cuerpo.
  static const pequeno = TextStyle(fontSize: 13);

  /// Texto secundario: descripciones y ayudas (13, pizarra).
  static const secundario = TextStyle(fontSize: 13, color: AppColors.pizarra, height: 1.4);

  /// Detalle bajo un título: fechas, archivo, especialidad (12,5, pizarra).
  static const detalle = TextStyle(fontSize: 12.5, color: AppColors.pizarra, height: 1.4);

  /// Dato breve resaltado bajo un título (12,5, pizarra, seminegrita).
  static const meta = TextStyle(fontSize: 12.5, color: AppColors.pizarra, fontWeight: FontWeight.w600);

  /// Notas al pie y datos técnicos (11, pizarra clara).
  static const mini = TextStyle(fontSize: 11, color: AppColors.pizarraClara);

  /// Rótulo en mayúsculas sobre un grupo de datos ("MÉTODO DE PAGO").
  static const rotulo = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.pizarra);
}
