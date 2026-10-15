import 'package:equatable/equatable.dart';

class Resena extends Equatable {
  const Resena({
    required this.id,
    required this.citaId,
    required this.puntualidad,
    required this.trato,
    required this.claridad,
    required this.instalaciones,
    required this.promedio,
    required this.publicadaEn,
    required this.editable,
    this.comentario,
    this.autor,
  });
  final String id;
  final String citaId;
  final int puntualidad, trato, claridad, instalaciones;
  final double promedio;
  final DateTime publicadaEn;
  final bool editable;
  final String? comentario;
  final String? autor;

  @override
  List<Object?> get props => [id, promedio, comentario, editable];
}

class EstadisticasResenas extends Equatable {
  const EstadisticasResenas({required this.total, required this.promedio, required this.puntualidad, required this.trato, required this.claridad, required this.instalaciones});
  final int total;
  final double promedio, puntualidad, trato, claridad, instalaciones;
  @override
  List<Object?> get props => [total, promedio];
}

class Calificaciones {
  const Calificaciones({required this.puntualidad, required this.trato, required this.claridad, required this.instalaciones, this.comentario});
  final int puntualidad, trato, claridad, instalaciones;
  final String? comentario;
}
