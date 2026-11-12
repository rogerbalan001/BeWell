import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../cubit/chat_cubit.dart';

/// Chat privado entre el paciente y el médico de una cita. Se actualiza solo cada 5 segundos.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.citaId, this.conQuien});
  final String citaId;

  /// Nombre de la otra parte, para el encabezado.
  final String? conQuien;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<ChatCubit>()..abrir(citaId), child: ChatVista(conQuien: conQuien));
  }
}

/// Contenido de la pantalla, separado para probarlo con un cubit de prueba.
class ChatVista extends StatefulWidget {
  const ChatVista({super.key, this.conQuien});
  final String? conQuien;

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _enviar() async {
    if (_texto.text.trim().isEmpty || _enviando) return;
    setState(() => _enviando = true);
    final error = await context.read<ChatCubit>().enviar(_texto.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
    } else {
      _texto.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, Recurso<ConversacionChat>>(
      listenWhen: (a, b) => (a.datosOpcional?.mensajes.length ?? 0) != (b.datosOpcional?.mensajes.length ?? 0),
      listener: (_, __) => _bajar(),
      builder: (context, estado) {
        return ContenidoCentrado(
          maxAncho: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Encabezado(
              antetitulo: 'Chat de la cita',
              titulo: widget.conQuien == null ? 'Conversación' : 'Chat con ${widget.conQuien}',
              descripcion: 'Solo tú y la otra parte de la cita ven estos mensajes. Para una emergencia, llama al servicio de emergencias.',
            ),
            Expanded(
              child: switch (estado) {
                RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<ChatCubit>().actualizar()),
                RecursoListo(:final datos) when datos.mensajes.isEmpty => const VistaVacia(
                    icono: Icons.chat_bubble_outline,
                    titulo: 'Aún no hay mensajes',
                    mensaje: 'Escribe tu primera pregunta sobre la consulta.',
                  ),
                RecursoListo(:final datos) => ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: datos.mensajes.length,
                    itemBuilder: (_, i) => BurbujaMensaje(datos.mensajes[i], mio: datos.esMio(datos.mensajes[i])),
                  ),
                _ => const VistaCargando(),
              },
            ),
            if (estado case RecursoListo(:final datos) when !datos.habilitado)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
                child: Text(
                  'El chat solo está disponible para citas confirmadas o atendidas.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.pizarra),
                ),
              )
            else if (estado is RecursoListo)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: TextField(
                      key: const Key('campo-mensaje'),
                      controller: _texto,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: longitudMaximaMensaje,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(hintText: 'Escribe un mensaje', counterText: '', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _enviando ? null : _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ]),
              ),
          ]),
        );
      },
    );
  }
}

/// Un mensaje: a la derecha y en azul si es propio; a la izquierda si es de la otra parte.
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje(this.mensaje, {super.key, required this.mio});
  final MensajeChat mensaje;
  final bool mio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mio ? AppColors.primario : AppColors.superficieAzul,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: mio ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Text(mensaje.texto, style: textos.bodyMedium?.copyWith(color: mio ? Colors.white : AppColors.marino)),
          const SizedBox(height: 4),
          Text(
            '${Formatos.fechaHora(mensaje.enviadoEn)}${mio && mensaje.leido ? ' · Leído' : ''}',
            style: textos.bodySmall?.copyWith(color: mio ? Colors.white : AppColors.pizarra),
          ),
        ]),
      ),
    );
  }
}
