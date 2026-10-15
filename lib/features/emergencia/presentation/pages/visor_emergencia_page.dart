import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/ficha_emergencia.dart';
import '../../domain/usecases/emergencia_usecases.dart';

/// Visor público de la ficha (lo abre cualquiera que escanee el QR, sin instalar la app).
/// Si quien escanea inició sesión como PERSONAL_EMERGENCIA, ve la ficha ampliada.
class VisorEmergenciaPage extends StatefulWidget {
  const VisorEmergenciaPage({super.key, required this.token});
  final String token;

  @override
  State<VisorEmergenciaPage> createState() => _VisorEmergenciaPageState();
}

class _VisorEmergenciaPageState extends State<VisorEmergenciaPage> {
  FichaEscaneada? _ficha;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final f = await sl<LeerFichaPorQr>()(widget.token);
      if (mounted) setState(() => _ficha = f);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e.noEncontrado ? 'Este código QR no es válido o fue regenerado por su titular.' : e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _ficha;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        title: const Row(children: [Icon(Icons.emergency), SizedBox(width: 8), Text('Ficha médica de emergencia')]),
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          maxAncho: 640,
          child: _error != null
              ? VistaError(_error!)
              : f == null
                  ? const VistaCargando()
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      BwTarjeta(
                        child: Row(children: [
                          AvatarIniciales(f.nombre, radio: 30),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(f.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              Text('${f.edad} años · ${f.sexo == 'F' ? 'Femenino' : f.sexo == 'M' ? 'Masculino' : 'Otro'}',
                                  style: const TextStyle(color: AppColors.pizarra)),
                            ]),
                          ),
                          if (f.ficha.grupoSanguineo != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
                              child: Column(children: [
                                const Text('SANGRE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
                                Text(f.ficha.grupoSanguineo!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      _bloque('Alergias', Icons.warning_amber_rounded, f.ficha.alergias, AppColors.error),
                      _bloque('Condiciones críticas', Icons.monitor_heart_outlined, f.ficha.condicionesCronicas, AppColors.ambar),
                      _bloque('Medicación actual', Icons.medication_outlined, f.ficha.medicacionActual, AppColors.primario),
                      if (f.ficha.contactos.isNotEmpty)
                        SeccionTarjeta(
                          titulo: 'Contactos de emergencia',
                          icono: Icons.call,
                          child: Column(children: [
                            for (final c in f.ficha.contactos)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.phone_in_talk, color: AppColors.verdeOscuro),
                                title: Text('${c.nombre} (${c.parentesco})'),
                                subtitle: SelectableText(c.telefono, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              ),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      ChipEstado(
                        f.ampliada ? 'Vista ampliada · personal de emergencia verificado' : 'Vista pública · solo datos autorizados por el paciente',
                        color: f.ampliada ? AppColors.verdeOscuro : AppColors.pizarra,
                        icono: Icons.shield_outlined,
                      ),
                      const SizedBox(height: 8),
                      const Text('Este acceso quedó registrado y se notificó al titular.', style: TextStyle(fontSize: 12, color: AppColors.pizarra)),
                      if (!f.ampliada)
                        TextButton(onPressed: () => context.go('/acceso?desde=${Uri.encodeComponent('/e/${widget.token}')}'), child: const Text('¿Personal de emergencia? Inicia sesión para ver la ficha completa')),
                    ]),
        ),
      ),
    );
  }

  Widget _bloque(String titulo, IconData icono, List<String> valores, Color color) {
    if (valores.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BwTarjeta(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icono, color: color),
            const SizedBox(width: 8),
            Text(titulo.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ]),
          const SizedBox(height: 8),
          for (final v in valores) Text('• $v', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)),
        ]),
      ),
    );
  }
}
