import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';

/// Pantalla de inicio pública (diseño Stitch "Bewell — Pantalla de inicio").
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final angosto = ancho < 900;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xF2EEF5FF),
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 72,
          title: const BwLogo(),
          actions: [
            if (!angosto) TextButton(onPressed: () => context.go('/verificar'), child: const Text('Verificar récipe')),
            TextButton(onPressed: () => context.go('/acceso'), child: const Text('Iniciar sesión')),
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 8),
              child: FilledButton(onPressed: () => context.go('/acceso?registro=1'), child: const Text('Reservar cita')),
            ),
          ],
        ),
        SliverToBoxAdapter(child: _Hero(angosto: angosto)),
        const SliverToBoxAdapter(child: _Cifras()),
        SliverToBoxAdapter(child: _Proposito(angosto: angosto)),
        const SliverToBoxAdapter(child: _Caracteristicas()),
        const SliverToBoxAdapter(child: _Equipo()),
        const SliverToBoxAdapter(child: _Pasos()),
        const SliverToBoxAdapter(child: _Llamado()),
        const SliverToBoxAdapter(child: _Pie()),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ChipEstado('TU SALUD, MÁS CERCA DE TI', color: AppColors.primario, fondo: Colors.white, icono: Icons.auto_awesome),
      const SizedBox(height: 22),
      Text.rich(
        const TextSpan(children: [
          TextSpan(text: 'Cuidarte debería\nser '),
          TextSpan(text: 'así de fácil.', style: TextStyle(color: AppColors.primario)),
        ]),
        style: TextStyle(fontSize: angosto ? 38 : 56, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -1.5),
      ),
      const SizedBox(height: 18),
      const Text(
        'Bewell conecta pacientes con médicos verificados para recibir atención presencial o en línea, '
        'con tu expediente siempre contigo y sin esperas innecesarias.',
        style: TextStyle(fontSize: 17, color: AppColors.pizarra, height: 1.6),
      ),
      const SizedBox(height: 26),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(onPressed: () => context.go('/acceso?registro=1'), icon: const Icon(Icons.arrow_forward), label: const Text('Encontrar un médico')),
        OutlinedButton(onPressed: () => context.go('/acceso'), child: const Text('Ya tengo cuenta')),
      ]),
      const SizedBox(height: 18),
      const Wrap(spacing: 18, children: [
        Text('✓ Médicos verificados', style: TextStyle(color: AppColors.pizarra, fontWeight: FontWeight.w600)),
        Text('✓ Datos protegidos', style: TextStyle(color: AppColors.pizarra, fontWeight: FontWeight.w600)),
      ]),
    ]);

    final tarjeta = Container(
      height: 380,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primario, Color(0xFF4B8BF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: AppColors.sombra, blurRadius: 40, offset: Offset(0, 20))],
      ),
      child: Stack(children: [
        const Positioned(right: -40, top: -40, child: Icon(Icons.favorite, size: 240, color: Color(0x1FFFFFFF))),
        Positioned(
          left: 24,
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
            child: const Row(children: [
              Icon(Icons.circle, size: 9, color: AppColors.verde),
              SizedBox(width: 6),
              Text('Especialistas disponibles hoy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              CircleAvatar(backgroundColor: AppColors.superficieAzul2, child: Icon(Icons.calendar_month, color: AppColors.primario)),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PRÓXIMA CONSULTA', style: TextStyle(fontSize: 11, color: AppColors.pizarra, fontWeight: FontWeight.w700)),
                  Text('Hoy, 10:30 a. m. · Videollamada', style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
              Icon(Icons.verified, color: AppColors.verde),
            ]),
          ),
        ),
      ]),
    );

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEEF5FF), AppColors.lienzo], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: ContenidoCentrado(
        padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: angosto ? 36 : 72),
        child: angosto
            ? Column(children: [texto, const SizedBox(height: 32), tarjeta])
            : Row(children: [Expanded(child: texto), const SizedBox(width: 48), Expanded(child: tarjeta)]),
      ),
    );
  }
}

class _Cifras extends StatelessWidget {
  const _Cifras();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.marino,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: ContenidoCentrado(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(alignment: WrapAlignment.spaceAround, spacing: 40, runSpacing: 24, children: [
          for (final (valor, texto) in const [
            ('100 %', 'Médicos verificados'),
            ('24/7', 'Acceso a tu historial'),
            ('< 200 ms', 'Ficha de emergencia'),
            ('ECDSA', 'Récipes con firma digital'),
          ])
            Column(children: [
              Text(valor, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              Text(texto, style: const TextStyle(color: Color(0xB3FFFFFF))),
            ]),
        ]),
      ),
    );
  }
}

class _Proposito extends StatelessWidget {
  const _Proposito({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final tarjeta = Container(
      padding: const EdgeInsets.all(36),
      height: 340,
      decoration: BoxDecoration(color: AppColors.primario, borderRadius: BorderRadius.circular(32)),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.medical_services_outlined, color: Colors.white)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('NUESTRO PROPÓSITO', style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w700, letterSpacing: 1.4, fontSize: 12)),
          SizedBox(height: 10),
          Text('Hacer que una mejor salud esté al alcance de todos.',
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.6)),
        ]),
      ]),
    );
    const texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Encabezado(
        antetitulo: 'Por qué existe Bewell',
        titulo: 'Atención médica que se adapta a tu vida',
        descripcion: 'Sabemos que cuidar de tu salud puede sentirse complejo. Por eso reunimos médicos, citas, consultas, '
            'exámenes y récipes en un solo lugar, y te damos el control de quién ve tu información.',
      ),
      Text('✓  Atención cercana y centrada en cada persona', style: TextStyle(fontWeight: FontWeight.w600)),
      SizedBox(height: 10),
      Text('✓  Acceso simple a profesionales de confianza', style: TextStyle(fontWeight: FontWeight.w600)),
      SizedBox(height: 10),
      Text('✓  Tecnología diseñada para cuidar, no para complicar', style: TextStyle(fontWeight: FontWeight.w600)),
    ]);
    return ContenidoCentrado(
      padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: 64),
      child: angosto
          ? Column(children: [tarjeta, const SizedBox(height: 32), texto])
          : Row(children: [Expanded(child: tarjeta), const SizedBox(width: 56), const Expanded(child: texto)]),
    );
  }
}

class _Caracteristicas extends StatelessWidget {
  const _Caracteristicas();
  @override
  Widget build(BuildContext context) {
    return ContenidoCentrado(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(children: [
        const Text('TODO EN UN MISMO LUGAR', style: TextStyle(color: AppColors.primario, fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('Tu salud, más simple y conectada', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
        const SizedBox(height: 28),
        Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center, children: [
          for (final (icono, titulo, texto) in const [
            (Icons.calendar_month_outlined, 'Citas sin complicaciones', 'Encuentra disponibilidad y agenda en pocos pasos.'),
            (Icons.folder_shared_outlined, 'Expediente que viaja contigo', 'Un único historial, independiente del médico.'),
            (Icons.lock_outline, 'Información protegida', 'Tú decides quién ve cada sección y hasta cuándo.'),
            (Icons.qr_code_2, 'Ficha de emergencia QR', 'Alergias y grupo sanguíneo para paramédicos.'),
          ])
            SizedBox(
              width: 260,
              child: BwTarjeta(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(backgroundColor: AppColors.superficieAzul2, child: Icon(icono, color: AppColors.primario)),
                  const SizedBox(height: 14),
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(texto, style: const TextStyle(color: AppColors.pizarra, height: 1.5)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _Equipo extends StatelessWidget {
  const _Equipo();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      color: AppColors.marinoProfundo,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: ContenidoCentrado(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PROFESIONALES QUE TE ESCUCHAN', style: TextStyle(color: Color(0xFF7FB0FF), fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Un equipo médico en quien confiar', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 28),
          FutureBuilder<List<Medico>>(
            future: sl<BuscarEspecialistas>()(),
            builder: (context, snap) {
              final medicos = (snap.data ?? const <Medico>[]).take(3).toList();
              if (medicos.isEmpty) {
                return const Text('Conecta el backend para ver a los especialistas verificados.', style: TextStyle(color: Colors.white70));
              }
              return Wrap(spacing: 18, runSpacing: 18, children: [
                for (final m in medicos)
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(28)),
                    child: Row(children: [
                      AvatarIniciales(m.nombreCompleto, radio: 30, verificado: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const ChipEstado('Médico verificado', color: AppColors.verde, fondo: Colors.white),
                          const SizedBox(height: 8),
                          Text(m.nombreCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                          Text(m.especialidad, style: const TextStyle(color: Colors.white70)),
                        ]),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos();
  @override
  Widget build(BuildContext context) {
    return ContenidoCentrado(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Encabezado(antetitulo: 'Fácil desde el primer paso', titulo: 'Empieza a cuidarte hoy'),
        Wrap(spacing: 32, runSpacing: 24, children: [
          for (final (n, titulo, texto) in const [
            ('01', 'Cuéntanos qué necesitas', 'Selecciona la especialidad o describe brevemente tus síntomas.'),
            ('02', 'Elige a tu especialista', 'Compara perfiles verificados, horarios y modalidades de consulta.'),
            ('03', 'Reserva y recibe atención', 'Confirma tu cita y empieza a cuidar de ti con acompañamiento profesional.'),
          ])
            SizedBox(
              width: 320,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primario, borderRadius: BorderRadius.circular(18)),
                  child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                Text(titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(texto, style: const TextStyle(color: AppColors.pizarra, height: 1.5)),
              ]),
            ),
        ]),
      ]),
    );
  }
}

class _Llamado extends StatelessWidget {
  const _Llamado();
  @override
  Widget build(BuildContext context) {
    return ContenidoCentrado(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
        decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(36)),
        child: Column(children: [
          const CircleAvatar(backgroundColor: Color(0x1FFFFFFF), child: Icon(Icons.favorite_border, color: Colors.white)),
          const SizedBox(height: 18),
          const Text('Tu bienestar empieza con una conversación',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 12),
          const Text('Encuentra al especialista que necesitas y da hoy el primer paso hacia una vida más saludable.',
              textAlign: TextAlign.center, style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.marino),
            onPressed: () => context.go('/acceso?registro=1'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Reservar mi cita'),
          ),
        ]),
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 56),
      color: AppColors.marinoProfundo,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: ContenidoCentrado(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 12, children: [
          const BwLogo(claro: true, tamano: 30),
          const Text('© 2026 Bewell. Cuidando de ti, estés donde estés.', style: TextStyle(color: Colors.white70)),
          TextButton(onPressed: () => context.go('/verificar'), child: const Text('Verificar récipe', style: TextStyle(color: Color(0xFF7FB0FF)))),
        ]),
      ),
    );
  }
}
