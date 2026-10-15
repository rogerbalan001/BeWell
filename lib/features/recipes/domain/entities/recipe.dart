import 'package:equatable/equatable.dart';

class ItemRecipe extends Equatable {
  const ItemRecipe({required this.medicamento, required this.presentacion, required this.dosis, required this.frecuencia, required this.duracionDias, this.indicaciones});
  final String medicamento, presentacion, dosis, frecuencia;
  final int duracionDias;
  final String? indicaciones;

  Map<String, dynamic> aJson() => {
        'medicamento': medicamento,
        'presentacion': presentacion,
        'dosis': dosis,
        'frecuencia': frecuencia,
        'duracionDias': duracionDias,
        if (indicaciones != null && indicaciones!.isNotEmpty) 'indicaciones': indicaciones,
      };

  @override
  List<Object?> get props => [medicamento, dosis, frecuencia, duracionDias];
}

class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.codigo,
    required this.urlVerificacion,
    required this.estado,
    required this.emitidoEn,
    required this.validoHasta,
    required this.items,
    required this.hash,
    required this.algoritmo,
    required this.medicoNombre,
    required this.especialidad,
    required this.pacienteNombre,
    this.diagnostico,
    this.motivoAnulacion,
  });
  final String id, codigo, urlVerificacion, estado, hash, algoritmo, medicoNombre, especialidad, pacienteNombre;
  final DateTime emitidoEn, validoHasta;
  final List<ItemRecipe> items;
  final String? diagnostico, motivoAnulacion;

  bool get vigente => estado == 'VIGENTE' && validoHasta.isAfter(DateTime.now());
  @override
  List<Object?> get props => [id, estado];
}

class VerificacionRecipe {
  const VerificacionRecipe({
    required this.encontrado,
    required this.valido,
    this.firmaValida = false,
    this.integro = false,
    this.vigente = false,
    this.estado,
    this.codigo,
    this.emitidoEn,
    this.validoHasta,
    this.medicoNombre,
    this.especialidad,
    this.medicoVerificado = false,
    this.colegiatura,
    this.pacienteNombre,
    this.pacienteCedula,
    this.items = const [],
    this.algoritmo,
    this.hash,
    this.motivoAnulacion,
  });
  final bool encontrado, valido, firmaValida, integro, vigente, medicoVerificado;
  final String? estado, codigo, medicoNombre, especialidad, colegiatura, pacienteNombre, pacienteCedula, algoritmo, hash, motivoAnulacion;
  final DateTime? emitidoEn, validoHasta;
  final List<ItemRecipe> items;
}
