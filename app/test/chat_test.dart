import 'package:bewell/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:bewell/features/chat/domain/entities/mensaje_chat.dart';
import 'package:bewell/features/chat/domain/repositories/chat_repository.dart';
import 'package:bewell/features/chat/domain/usecases/chat_usecases.dart';
import 'package:bewell/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:bewell/features/chat/presentation/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

MensajeChat _m(String id, String autor, String texto, int minuto) =>
    MensajeChat(id: id, autor: autor, texto: texto, enviadoEn: DateTime(2026, 11, 5, 10, minuto));

class _ChatFalso implements ChatRepository {
  _ChatFalso({this.habilitado = true});
  bool habilitado;
  final servidor = <MensajeChat>[_m('1', 'MEDICO', 'Hola, ¿en qué te ayudo?', 0)];
  final leidos = <String>[];
  final despuesDePedidos = <DateTime?>[];

  @override
  Future<ConversacionChat> conversacion(String citaId, {DateTime? despuesDe}) async {
    despuesDePedidos.add(despuesDe);
    final mensajes = servidor.where((m) => despuesDe == null || m.enviadoEn.isAfter(despuesDe)).toList();
    return ConversacionChat(citaId: citaId, miParte: 'PACIENTE', habilitado: habilitado, mensajes: mensajes);
  }

  @override
  Future<MensajeChat> enviar(String citaId, String texto) async {
    final m = _m('${servidor.length + 1}', 'PACIENTE', texto, servidor.length);
    servidor.add(m);
    return m;
  }

  @override
  Future<void> marcarLeidos(String citaId) async => leidos.add(citaId);

  @override
  Future<Map<String, int>> noLeidos() async => {'c1': 2};
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('ChatCubit', () {
    test('abre la conversación y marca como leídos los mensajes recibidos', () async {
      final repo = _ChatFalso();
      final cubit = ChatCubit(ConversarEnCita(repo), intervalo: null);
      await cubit.abrir('c1');
      expect(cubit.state.datosOpcional!.mensajes, hasLength(1));
      expect(repo.leidos, ['c1']);
      await cubit.close();
    });

    test('actualizar pide solo los posteriores al último y agrega los nuevos sin repetir', () async {
      final repo = _ChatFalso();
      final cubit = ChatCubit(ConversarEnCita(repo), intervalo: null);
      await cubit.abrir('c1');
      repo.servidor.add(_m('2', 'MEDICO', 'Ven en ayunas', 3));
      await cubit.actualizar();
      await cubit.actualizar();
      expect(repo.despuesDePedidos.last, DateTime(2026, 11, 5, 10, 3));
      expect(cubit.state.datosOpcional!.mensajes.map((m) => m.texto), ['Hola, ¿en qué te ayudo?', 'Ven en ayunas']);
      await cubit.close();
    });

    test('enviar agrega el mensaje propio y rechaza los vacíos', () async {
      final repo = _ChatFalso();
      final cubit = ChatCubit(ConversarEnCita(repo), intervalo: null);
      await cubit.abrir('c1');
      expect(await cubit.enviar('   '), 'Escribe un mensaje');
      expect(await cubit.enviar('¿Llevo mis exámenes?'), isNull);
      final c = cubit.state.datosOpcional!;
      expect(c.esMio(c.mensajes.last), isTrue);
      expect(c.mensajes.last.texto, '¿Llevo mis exámenes?');
      await cubit.close();
    });

    test('el contador de no leídos es por cita', () async {
      expect(await ConversarEnCita(_ChatFalso()).noLeidosDe('c1'), 2);
      expect(await ConversarEnCita(_ChatFalso()).noLeidosDe('otra'), 0);
      expect(ChatMapper.noLeidos({'total': 3, 'porCita': [{'citaId': 'c1', 'noLeidos': 3}]}), {'c1': 3});
    });
  });

  group('ChatVista', () {
    Future<_ChatFalso> montar(WidgetTester tester, {bool habilitado = true}) async {
      final repo = _ChatFalso(habilitado: habilitado);
      final cubit = ChatCubit(ConversarEnCita(repo), intervalo: null);
      await cubit.abrir('c1');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BlocProvider<ChatCubit>.value(value: cubit, child: const ChatVista(conQuien: 'Dra. Soto'))),
      ));
      await tester.pump();
      return repo;
    }

    testWidgets('muestra los mensajes y envía uno nuevo', (tester) async {
      final repo = await montar(tester);
      expect(find.text('Chat con Dra. Soto'), findsOneWidget);
      expect(find.text('Hola, ¿en qué te ayudo?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('campo-mensaje')), 'Gracias, doctora');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pump();
      expect(repo.servidor.last.texto, 'Gracias, doctora');
      expect(find.text('Gracias, doctora'), findsOneWidget);
    });

    testWidgets('con la cita cancelada no deja escribir', (tester) async {
      await montar(tester, habilitado: false);
      expect(find.byKey(const Key('campo-mensaje')), findsNothing);
      expect(find.textContaining('solo está disponible'), findsOneWidget);
    });
  });
}
