import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/medico.dart';
import '../../domain/usecases/medicos_usecases.dart';
import '../cubit/medicos_cubits.dart';

/// HU: el médico sube título, número de colegiatura y documento de identidad
/// para que su perfil sea público.
class CredencialesPage extends StatelessWidget {
  const CredencialesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MiPerfilMedicoCubit>()..cargar(),
      child: BlocBuilder<MiPerfilMedicoCubit, Recurso<Medico>>(builder: (context, estado) {
        return switch (estado) {
          RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<MiPerfilMedicoCubit>().cargar()),
          RecursoListo(:final datos) => _Contenido(datos),
          _ => const VistaCargando(),
        };
      }),
    );
  }
}

Color colorEstadoVerificacion(String? estado) => switch (estado) {
      'APROBADO' => AppColors.verde,
      'RECHAZADO' => AppColors.error,
      _ => AppColors.ambar,
    };

String textoEstadoVerificacion(String? estado) => switch (estado) {
      'APROBADO' => 'Aprobado',
      'RECHAZADO' => 'Rechazado',
      _ => 'Pendiente de revisión',
    };

class _Contenido extends StatelessWidget {
  const _Contenido(this.medico);
  final Medico medico;

  @override
  Widget build(BuildContext context) {
    final verificado = medico.estadoVerificacion == 'APROBADO';
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 900,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Encabezado(
            antetitulo: 'Verificación profesional',
            titulo: 'Mis credenciales',
            descripcion: 'Tu perfil aparece en el directorio con la insignia "Médico verificado" cuando el administrador aprueba las tres credenciales.',
          ),
          BwTarjeta(
            color: verificado ? AppColors.verdeSuave : AppColors.ambarSuave,
            child: Row(children: [
              Icon(verificado ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                  color: verificado ? AppColors.verdeOscuro : AppColors.ambar, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  verificado
                      ? 'Perfil verificado: ya eres visible para los pacientes y puedes firmar récipes.'
                      : medico.estadoVerificacion == 'RECHAZADO'
                          ? 'Alguna credencial fue rechazada. Revisa el motivo y vuelve a cargarla.'
                          : 'Tu perfil está en revisión. Carga las tres credenciales para completar la verificación.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          for (final tipo in const ['TITULO', 'COLEGIATURA', 'CEDULA'])
            Padding(padding: const EdgeInsets.only(bottom: 14), child: _TarjetaCredencial(tipo: tipo, medico: medico)),
        ]),
      ),
    );
  }
}

class _TarjetaCredencial extends StatelessWidget {
  const _TarjetaCredencial({required this.tipo, required this.medico});
  final String tipo;
  final Medico medico;

  String get _nombre => switch (tipo) { 'TITULO' => 'Título de médico', 'COLEGIATURA' => 'Número de colegiatura', _ => 'Cédula de identidad' };

  @override
  Widget build(BuildContext context) {
    Credencial? actual;
    for (final c in medico.credenciales) {
      if (c.tipo == tipo) actual = c;
    }
    return SeccionTarjeta(
      titulo: _nombre,
      icono: tipo == 'CEDULA' ? Icons.badge_outlined : Icons.workspace_premium_outlined,
      accion: actual == null
          ? const ChipEstado('Sin cargar', color: AppColors.pizarraClara)
          : ChipEstado(textoEstadoVerificacion(actual.estado), color: colorEstadoVerificacion(actual.estado)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (actual != null) Text('N.º ${actual.numero}', style: const TextStyle(fontWeight: FontWeight.w600)),
        if (actual?.observaciones != null) ...[
          const SizedBox(height: 6),
          Text('Motivo del rechazo: ${actual!.observaciones}', style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 10),
        if (actual?.estado != 'APROBADO')
          OutlinedButton.icon(
            onPressed: () => _cargar(context),
            icon: const Icon(Icons.upload_file),
            label: Text(actual == null ? 'Cargar documento' : 'Reemplazar documento'),
          ),
      ]),
    );
  }

  Future<void> _cargar(BuildContext context) async {
    final numero = TextEditingController();
    PlatformFile? archivo;
    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Cargar $_nombre'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: numero, decoration: AppTheme.campo('Número del documento')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'], withData: true);
                  if (r != null && r.files.isNotEmpty) setLocal(() => archivo = r.files.first);
                },
                icon: const Icon(Icons.attach_file),
                label: Text(archivo?.name ?? 'Elegir archivo (PDF, JPG o PNG, máx. 10 MB)'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar a revisión')),
          ],
        ),
      ),
    );
    if (enviar != true || !context.mounted) return;
    final elegido = archivo;
    if (elegido?.bytes == null || numero.text.trim().isEmpty) {
      mostrarMensaje(context, 'Indica el número y adjunta el archivo', error: true);
      return;
    }
    if (elegido!.size > 10 * 1024 * 1024) {
      mostrarMensaje(context, 'El archivo supera 10 MB', error: true);
      return;
    }
    final error = await intentar(() => sl<SubirCredencial>()(tipo, numero.text.trim(), elegido.bytes!, elegido.name));
    if (!context.mounted) return;
    mostrarMensaje(context, error ?? 'Documento enviado a revisión', error: error != null);
    if (error == null) context.read<MiPerfilMedicoCubit>().cargar(silencioso: true);
  }
}
