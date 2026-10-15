import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../auth/domain/entities/usuario_sesion.dart';
import '../../../auth/presentation/cubit/sesion_cubit.dart';
import '../../../citas/domain/entities/cita.dart';
import '../../../citas/domain/usecases/citas_usecases.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';

/// Tablero de inicio según el rol del usuario.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<SesionCubit>().state.usuario;
    if (u == null) return const VistaCargando();
    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Encabezado(antetitulo: _saludo(), titulo: 'Hola, ${u.nombreMostrado.split(' ').first}'),
          if (u.esPaciente) const _InicioPaciente(),
          if (u.esMedico) const _InicioMedico(),
          if (u.esAdmin) _accesos(context, const [
            (Icons.verified_user_outlined, 'Verificación de médicos', 'Revisa título, colegiatura y cédula', '/admin/verificaciones'),
          ]),
          if (u.esEmergencia) const _InicioEmergencia(),
        ]),
      ),
    );
  }

  static String _saludo() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Buenos días' : (h < 19 ? 'Buenas tardes' : 'Buenas noches');
  }
}

Widget _accesos(BuildContext context, List<(IconData, String, String, String)> items) {
  return Wrap(spacing: 14, runSpacing: 14, children: [
    for (final (icono, titulo, texto, ruta) in items)
      SizedBox(
        width: 270,
        child: BwTarjeta(
          onTap: () => context.push(ruta),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(backgroundColor: AppColors.superficieAzul2, child: Icon(icono, color: AppColors.primario)),
            const SizedBox(height: 12),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(texto, style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
          ]),
        ),
      ),
  ]);
}

class _InicioPaciente extends StatelessWidget {
  const _InicioPaciente();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BlocBuilder<PerfilActivoCubit, PerfilesState>(builder: (context, s) {
        return BwTarjeta(
          color: AppColors.marino,
          borde: Colors.transparent,
          padding: const EdgeInsets.all(24),
          child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PERFIL ACTIVO', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(s.seleccionado?.nombreCompleto ?? '—', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('${s.perfiles.length} perfiles en tu familia', style: const TextStyle(color: Colors.white70)),
            ]),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.marino),
              onPressed: () => context.push('/directorio'),
              icon: const Icon(Icons.event_available),
              label: const Text('Reservar cita'),
            ),
          ]),
        );
      }),
      const SizedBox(height: 16),
      const _ProximaCita(),
      const SizedBox(height: 20),
      _accesos(context, const [
        (Icons.folder_shared_outlined, 'Mi expediente', 'Línea de tiempo y antecedentes', '/expediente'),
        (Icons.admin_panel_settings_outlined, 'Médicos autorizados', 'Quién ve qué y hasta cuándo', '/expediente/permisos'),
        (Icons.biotech_outlined, 'Exámenes', 'Sube PDF o fotos y extrae valores', '/examenes'),
        (Icons.receipt_long_outlined, 'Récipes', 'Récipes firmados con QR', '/recipes'),
        (Icons.qr_code_2, 'Ficha de emergencia', 'Pase médico con código QR', '/emergencia'),
        (Icons.family_restroom, 'Mi familia', 'Perfiles de hijos y padres', '/perfiles'),
      ]),
    ]);
  }
}

class _ProximaCita extends StatelessWidget {
  const _ProximaCita();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cita>>(
      future: sl<ListarCitas>()(estados: const ['CONFIRMADA', 'PENDIENTE_ACEPTACION']),
      builder: (context, snap) {
        final futuras = (snap.data ?? const <Cita>[]).where((c) => c.fin.isAfter(DateTime.now())).toList()
          ..sort((a, b) => a.inicio.compareTo(b.inicio));
        if (futuras.isEmpty) return const SizedBox.shrink();
        final c = futuras.first;
        return BwTarjeta(
          onTap: () => context.push('/citas/${c.id}'),
          child: Row(children: [
            const CircleAvatar(radius: 24, backgroundColor: AppColors.superficieAzul2, child: Icon(Icons.calendar_month, color: AppColors.primario)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.pendienteAceptacion ? 'PROPUESTA POR RESPONDER' : 'PRÓXIMA CONSULTA',
                    style: const TextStyle(fontSize: 11, color: AppColors.pizarra, fontWeight: FontWeight.w700, letterSpacing: 1)),
                Text('${Formatos.fechaLarga(c.inicio)}, ${Formatos.hora(c.inicio)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${c.medicoNombre} · ${c.esVirtual ? 'Videollamada' : 'Presencial'} · ${c.pacienteNombre}', style: const TextStyle(color: AppColors.pizarra)),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ]),
        );
      },
    );
  }
}

class _InicioMedico extends StatelessWidget {
  const _InicioMedico();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FutureBuilder<Medico>(
        future: sl<ObtenerMiPerfilMedico>()(),
        builder: (context, snap) {
          final m = snap.data;
          if (m == null || m.estadoVerificacion == 'APROBADO') return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BwTarjeta(
              color: AppColors.ambarSuave,
              onTap: () => context.push('/medico/credenciales'),
              child: const Row(children: [
                Icon(Icons.hourglass_top, color: AppColors.ambar),
                SizedBox(width: 12),
                Expanded(child: Text('Tu perfil aún no es público: completa la verificación de credenciales.', style: TextStyle(fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right),
              ]),
            ),
          );
        },
      ),
      SeccionTarjeta(
        titulo: 'Consultas de hoy',
        icono: Icons.today,
        accion: TextButton(onPressed: () => context.push('/citas'), child: const Text('Ver agenda')),
        child: FutureBuilder<List<Cita>>(
          future: sl<ListarCitas>()(estados: const ['CONFIRMADA']),
          builder: (context, snap) {
            final hoy = DateTime.now();
            final citas = (snap.data ?? const <Cita>[])
                .where((c) => c.inicio.year == hoy.year && c.inicio.month == hoy.month && c.inicio.day == hoy.day)
                .toList()
              ..sort((a, b) => a.inicio.compareTo(b.inicio));
            if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
            if (citas.isEmpty) return const Text('No tienes consultas confirmadas para hoy.', style: TextStyle(color: AppColors.pizarra));
            return Column(children: [
              for (final c in citas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: AppColors.superficieAzul2, child: Text(Formatos.hora(c.inicio).split(' ').first, style: const TextStyle(fontSize: 11))),
                  title: Text(c.pacienteNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${c.esVirtual ? 'Videollamada' : 'Presencial'} · ${c.motivo.isEmpty ? 'Sin motivo' : c.motivo}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/citas/${c.id}'),
                ),
            ]);
          },
        ),
      ),
      const SizedBox(height: 20),
      _accesos(context, const [
        (Icons.schedule, 'Mi agenda', 'Horario, modalidades y política', '/medico/agenda'),
        (Icons.folder_shared_outlined, 'Mis pacientes', 'Expedientes autorizados', '/medico/pacientes'),
        (Icons.forward_to_inbox_outlined, 'Referencias', 'Enviadas y recibidas', '/referencias'),
        (Icons.receipt_long_outlined, 'Récipes emitidos', 'Firmados y verificables', '/recipes'),
        (Icons.workspace_premium_outlined, 'Mis credenciales', 'Título, colegiatura y cédula', '/medico/credenciales'),
      ]),
    ]);
  }
}

class _InicioEmergencia extends StatefulWidget {
  const _InicioEmergencia();
  @override
  State<_InicioEmergencia> createState() => _InicioEmergenciaState();
}

class _InicioEmergenciaState extends State<_InicioEmergencia> {
  final _codigo = TextEditingController();

  void _abrir() {
    final texto = _codigo.text.trim();
    if (texto.isEmpty) return;
    final token = texto.contains('/e/') ? texto.split('/e/').last : texto;
    context.push('/e/$token');
  }

  @override
  Widget build(BuildContext context) {
    final UsuarioSesion? u = context.read<SesionCubit>().usuario;
    return SeccionTarjeta(
      titulo: 'Lectura de ficha de emergencia',
      subtitulo: 'Sesión de ${u?.email ?? ''}: verás la ficha ampliada del paciente',
      icono: Icons.emergency_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Escanea el QR con la cámara del teléfono (abre la ficha en el navegador) o pega aquí el enlace del QR.'),
        const SizedBox(height: 12),
        TextField(controller: _codigo, decoration: AppTheme.campo('Enlace o código del QR', icono: Icons.qr_code_scanner), onSubmitted: (_) => _abrir()),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _abrir, icon: const Icon(Icons.search), label: const Text('Abrir ficha')),
      ]),
    );
  }
}
