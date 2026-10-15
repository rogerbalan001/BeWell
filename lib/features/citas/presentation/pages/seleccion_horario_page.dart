import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/estado/recurso.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../perfiles/presentation/cubit/perfil_activo_cubit.dart';
import '../../../perfiles/presentation/widgets/selector_perfil.dart';
import '../../domain/entities/cita.dart';
import '../cubit/citas_cubits.dart';
import '../widgets/selector_franjas.dart';

/// Paso 2 de 3: "Elige fecha, hora y modalidad".
class SeleccionHorarioPage extends StatelessWidget {
  const SeleccionHorarioPage({super.key, required this.medicoId});
  final String medicoId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HorarioCubit>()..cargar(medicoId),
      child: BlocBuilder<HorarioCubit, Recurso<DatosHorario>>(builder: (context, estado) {
        return switch (estado) {
          RecursoError(:final mensaje) => VistaError(mensaje, reintentar: () => context.read<HorarioCubit>().cargar(medicoId)),
          RecursoListo(:final datos) => _Formulario(datos),
          _ => const VistaCargando(),
        };
      }),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario(this.datos);
  final DatosHorario datos;
  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late String _modalidad = widget.datos.medico.ofreceVirtual ? 'VIRTUAL' : 'PRESENCIAL';
  Franja? _franja;
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _continuar() {
    final f = _franja;
    if (f == null) {
      mostrarMensaje(context, 'Elige un horario', error: true);
      return;
    }
    context.push('/agendar/${widget.datos.medico.id}/confirmar',
        extra: BorradorCita(medico: widget.datos.medico, franja: f, modalidad: _modalidad, motivo: _motivo.text.trim()));
  }

  Widget _tarjetaModalidad(String valor, IconData icono, String titulo, String texto) {
    final activo = _modalidad == valor;
    return Expanded(
      child: BwTarjeta(
        color: activo ? AppColors.superficieAzul2 : AppColors.superficieAzul,
        borde: activo ? AppColors.primario : Colors.transparent,
        padding: const EdgeInsets.all(16),
        onTap: () => setState(() => _modalidad = valor),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: activo ? AppColors.primario : Colors.white, child: Icon(icono, color: activo ? Colors.white : AppColors.pizarra)),
            const Spacer(),
            if (activo) const ChipEstado('Activa', icono: Icons.check, color: AppColors.primario),
          ]),
          const SizedBox(height: 10),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(texto, style: const TextStyle(color: AppColors.pizarra, fontSize: 12.5)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.datos.medico;
    final ancho = MediaQuery.sizeOf(context).width;
    final formulario = Column(children: [
      BwTarjeta(
        child: Row(children: [
          AvatarIniciales(m.nombreCompleto, radio: 28, verificado: m.verificado),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              Text('${m.especialidad} · ★ ${m.calificacion.toStringAsFixed(1)} (${m.totalResenas} reseñas)',
                  style: const TextStyle(color: AppColors.pizarra, fontSize: 13)),
            ]),
          ),
          TextButton.icon(onPressed: () => context.go('/directorio'), icon: const Icon(Icons.swap_horiz), label: const Text('Cambiar')),
        ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: '1. Modalidad de la consulta',
        subtitulo: 'Elige cómo prefieres recibir tu atención médica',
        child: Row(children: [
          if (m.ofreceVirtual)
            _tarjetaModalidad('VIRTUAL', Icons.videocam_outlined, 'Consulta en línea', 'Videollamada cifrada, récipe digital y sin traslado.'),
          if (m.ofreceVirtual && m.ofrecePresencial) const SizedBox(width: 12),
          if (m.ofrecePresencial)
            _tarjetaModalidad('PRESENCIAL', Icons.apartment_outlined, 'Presencial', m.direccion ?? 'En el consultorio del médico.'),
        ]),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: '2 y 3. Fecha y horario',
        subtitulo: 'Horarios en tu zona horaria local',
        child: SelectorFranjas(franjas: widget.datos.franjas, seleccionada: _franja, alElegir: (f) => setState(() => _franja = f)),
      ),
      const SizedBox(height: 16),
      SeccionTarjeta(
        titulo: '4. Motivo de la visita',
        subtitulo: 'Ayudará al médico a preparar tu consulta',
        child: TextField(
          controller: _motivo,
          maxLines: 3,
          maxLength: 1000,
          decoration: AppTheme.campo('Describe brevemente la razón de tu visita o tus síntomas'),
        ),
      ),
    ]);

    final resumen = BwTarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('RESUMEN PRELIMINAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.pizarra)),
        const SizedBox(height: 12),
        const Row(children: [Text('Paciente:', style: TextStyle(color: AppColors.pizarra)), SizedBox(width: 8), SelectorPerfil()]),
        const Divider(height: 24),
        FilaDato('Fecha', _franja == null ? '—' : Formatos.fechaLarga(_franja!.inicio), icono: Icons.calendar_today_outlined),
        FilaDato('Hora', _franja == null ? '—' : Formatos.hora(_franja!.inicio), icono: Icons.schedule),
        FilaDato('Modalidad', _modalidad == 'VIRTUAL' ? 'Videollamada' : 'Presencial', icono: Icons.videocam_outlined),
        const Divider(height: 24),
        FilaDato('Total a confirmar', Formatos.dinero(m.tarifa, m.moneda), destacado: true),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.verde, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Política ${m.politica.nombre.toLowerCase()}: ${m.politica.descripcion}', style: const TextStyle(fontSize: 12.5))),
          ]),
        ),
        const SizedBox(height: 16),
        BlocBuilder<PerfilActivoCubit, PerfilesState>(
          builder: (context, s) => FilledButton.icon(
            onPressed: s.seleccionado == null ? null : _continuar,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar a confirmación'),
          ),
        ),
      ]),
    );

    return SingleChildScrollView(
      child: ContenidoCentrado(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const IndicadorPasos(pasos: ['Especialista', 'Fecha y modalidad', 'Confirmación'], actual: 1),
          const SizedBox(height: 22),
          const Encabezado(antetitulo: 'Proceso de agendamiento', titulo: 'Elige fecha, hora y modalidad'),
          if (ancho >= 1000)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: formulario),
              const SizedBox(width: 24),
              SizedBox(width: 340, child: resumen),
            ])
          else ...[
            formulario,
            const SizedBox(height: 16),
            resumen,
          ],
        ]),
      ),
    );
  }
}
