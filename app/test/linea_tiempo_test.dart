import 'package:bewell/features/expediente/domain/entities/expediente.dart';
import 'package:flutter_test/flutter_test.dart';

EventoClinico evento(String id, {String tipo = 'CONSULTA', Map<String, String> detalles = const {}}) => EventoClinico(
      id: id,
      tipo: tipo,
      categoria: 'CONSULTAS',
      fecha: DateTime(2026, 10, 14),
      titulo: 'Evento $id',
      resumen: '',
      detalles: detalles,
      autoReportado: false,
    );

void main() {
  test('los detalles se muestran en palabras y se ocultan las claves internas', () {
    final e = evento('1', tipo: 'EXAMEN', detalles: const {'estadoExtraccion': 'NO_RECONOCIDO', 'tipoMime': 'image/png', 'autoReportado': 'true'});
    expect(e.detallesLegibles, [('Lectura de valores', 'Guardado como adjunto'), ('Archivo', 'Imagen')]);
  });

  test('una orden de exámenes muestra su estado', () {
    expect(evento('1', tipo: 'SOLICITUD_EXAMEN', detalles: const {'estado': 'COMPLETADA'}).estadoOrden, 'Resultados cargados');
    expect(evento('2').estadoOrden, isNull);
  });

  test('"Ver más" agrega la página siguiente sin repetir eventos', () {
    final primera = PaginaEventos(items: [evento('1'), evento('2')], total: 3, categoriasPermitidas: const [], esTitular: true);
    expect(primera.hayMas, isTrue);
    final todas = primera.conSiguiente(PaginaEventos(items: [evento('2'), evento('3')], total: 3, categoriasPermitidas: const [], esTitular: true));
    expect(todas.items.map((e) => e.id), ['1', '2', '3']);
    expect(todas.hayMas, isFalse);
  });
}
