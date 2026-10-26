import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../domain/entities/examen.dart';
import '../../domain/usecases/examenes_usecases.dart';

/// HU: subir fotos o PDF de exámenes y que la app extraiga los valores.
class SubirExamenPage extends StatefulWidget {
  const SubirExamenPage({super.key, this.solicitudId, this.tituloSugerido});
  final String? solicitudId;
  final String? tituloSugerido;

  @override
  State<SubirExamenPage> createState() => _SubirExamenPageState();
}

class _SubirExamenPageState extends State<SubirExamenPage> {
  late final _titulo = TextEditingController(text: widget.tituloSugerido ?? '');
  PlatformFile? _archivo;
  DateTime _fecha = DateTime.now();
  bool _subiendo = false;

  Future<void> _elegir() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: SubirExamen.extensiones, withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    if (!SubirExamen.extensiones.contains((f.extension ?? '').toLowerCase())) {
      if (mounted) mostrarMensaje(context, 'Formato no permitido: usa JPG, PNG o PDF', error: true);
      return;
    }
    if (f.size > SubirExamen.tamanoMaximo) {
      if (mounted) mostrarMensaje(context, 'El archivo supera el máximo de 10 MB', error: true);
      return;
    }
    setState(() => _archivo = f);
  }

  Future<void> _subir(String pacienteId) async {
    final f = _archivo;
    if (f?.bytes == null || _titulo.text.trim().isEmpty) {
      mostrarMensaje(context, 'Indica el nombre del examen y elige el archivo', error: true);
      return;
    }
    setState(() => _subiendo = true);
    try {
      final examen = await sl<SubirExamen>()(
        pacienteId: pacienteId,
        titulo: _titulo.text.trim(),
        archivo: ArchivoExamen(bytes: f!.bytes!, nombre: f.name),
        solicitudId: widget.solicitudId,
        fechaExamen: _fecha,
      );
      if (!mounted) return;
      if (examen.estadoExtraccion == 'EXTRAIDO') {
        mostrarMensaje(context, 'Detectamos ${examen.resultados.length} valores. Revísalos antes de guardar.');
        context.pushReplacement('/examenes/${examen.id}/revisar', extra: examen);
      } else {
        mostrarMensaje(context, 'No reconocimos valores en el documento: quedó guardado como adjunto en tu expediente.');
        context.pop();
      }
    } on Failure catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilActivoCubit>().state.seleccionado;
    return SingleChildScrollView(
      child: ContenidoCentrado(
        maxAncho: 720,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Encabezado(
            antetitulo: 'Digitaliza tus resultados',
            titulo: 'Subir examen',
            descripcion: 'Para ${perfil?.nombreCompleto ?? 'el perfil activo'}. Se aceptan archivos JPG, PNG y PDF de hasta 10 MB.',
          ),
          BwTarjeta(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _titulo, decoration: AppTheme.campo('Nombre del examen (p. ej. "Perfil lipídico")', icono: Icons.biotech_outlined)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text('Fecha del examen: ${Formatos.fechaCorta(_fecha)}'),
                onPressed: () async {
                  final f = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (f != null) setState(() => _fecha = f);
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _elegir,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.superficieAzul,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primario.withAlpha(90), width: 1.5),
                  ),
                  child: Column(children: [
                    Icon(_archivo == null ? Icons.cloud_upload_outlined : Icons.insert_drive_file_outlined, size: 44, color: AppColors.primario),
                    const SizedBox(height: 8),
                    Text(_archivo?.name ?? 'Toca para elegir una foto o un PDF', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (_archivo != null)
                      Text('${(_archivo!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: const TextStyle(color: AppColors.pizarra)),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _subiendo || perfil == null ? null : () => _subir(perfil.id),
                icon: _subiendo
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_subiendo ? 'Procesando…' : 'Subir y extraer valores'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Los valores extraídos automáticamente no se consideran clínicamente confiables hasta que tú los confirmas y un médico los valida.',
                style: TextStyle(fontSize: 12, color: AppColors.pizarra),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
