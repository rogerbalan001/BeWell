import 'package:bewell/features/examenes/domain/entities/examen.dart';
import 'package:bewell/features/examenes/presentation/widgets/resultados_por_validar.dart';
import 'package:flutter_test/flutter_test.dart';

Examen examen(String id, {required String estado, bool validado = false, bool conResultados = true}) => Examen(
      id: id,
      pacienteId: 'p1',
      titulo: 'Hematología $id',
      tipoMime: 'application/pdf',
      nombreArchivo: '$id.pdf',
      estadoExtraccion: estado,
      resultados: conResultados
          ? [ResultadoAnalito(analito: 'Hemoglobina', valor: '13.5', unidad: 'g/dL', validadoPorMedico: validado)]
          : const [],
      validadoPorMedico: validado,
      cargadoEn: DateTime(2026, 11, 20),
    );

void main() {
  test('el médico solo ve por validar los exámenes confirmados por el paciente y sin validar', () {
    final lista = [
      examen('a', estado: 'CONFIRMADO'),
      examen('b', estado: 'CONFIRMADO', validado: true),
      examen('c', estado: 'EXTRAIDO'),
      examen('d', estado: 'SIN_EXTRACCION', conResultados: false),
    ];
    expect(pendientesDeValidar(lista).map((e) => e.id), ['a']);
  });

  test('el paciente ve el examen validado con su estado', () {
    expect(examen('b', estado: 'CONFIRMADO', validado: true).estadoLegible, 'Validado por médico');
  });
}
