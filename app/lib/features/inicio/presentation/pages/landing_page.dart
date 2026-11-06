import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../../medicos/domain/entities/medico.dart';
import '../../../medicos/domain/usecases/medicos_usecases.dart';

/// Portada pública de Bewell.
///
/// Dirección visual: la de un buen prospecto clínico. Mucho blanco, el azul de
/// la marca reservado para acciones e identidad, información jerarquizada y un
/// solo momento memorable: el trazo del pulso que se dibuja una vez en la
/// tarjeta principal.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();

  void _arriba() {
    if (!_scroll.hasClients) return;
    final reducir = MediaQuery.of(context).disableAnimations;
    if (reducir) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final angosto = ancho < 900;
    return Scaffold(
      backgroundColor: AppColors.superficie,
      body: CustomScrollView(controller: _scroll, slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.superficie.withAlpha(242),
          toolbarHeight: 68,
          titleSpacing: angosto ? 12 : 28,
          title: BwLogo(tamano: 32, alPulsar: _arriba),
          actions: [
            if (!angosto) TextButton(onPressed: () => context.go('/verificar'), child: const Text('Verificar récipe')),
            TextButton(onPressed: () => context.go('/acceso'), child: const Text('Iniciar sesión')),
            Padding(
              padding: EdgeInsets.only(right: angosto ? 12 : 28, left: 6),
              child: FilledButton(onPressed: () => context.go('/acceso?registro=1'), child: const Text('Reservar cita')),
            ),
          ],
        ),
        SliverToBoxAdapter(child: _Hero(angosto: angosto)),
        SliverToBoxAdapter(child: _Garantias(angosto: angosto)),
        SliverToBoxAdapter(child: _Proposito(angosto: angosto)),
        SliverToBoxAdapter(child: _Caracteristicas(angosto: angosto)),
        const SliverToBoxAdapter(child: _Equipo()),
        SliverToBoxAdapter(child: _Pasos(angosto: angosto)),
        const SliverToBoxAdapter(child: _Llamado()),
        SliverToBoxAdapter(child: _Pie(alLogo: _arriba)),
      ]),
    );
  }
}

/* ───────────────────────────── Hero ───────────────────────────── */

class _Hero extends StatelessWidget {
  const _Hero({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cuidarte debería ser así de fácil.', style: angosto ? t.displaySmall : t.displayLarge),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          'Bewell te conecta con médicos verificados para consultas presenciales o en línea. '
          'Tu expediente va contigo de un médico a otro, y tú decides quién lo ve.',
          style: t.bodyLarge?.copyWith(fontSize: angosto ? 16.5 : 18),
        ),
      ),
      const SizedBox(height: 28),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(
          onPressed: () => context.go('/acceso?registro=1'),
          icon: const Icon(Icons.search_rounded, size: 20),
          label: const Text('Encontrar un médico'),
        ),
        OutlinedButton(onPressed: () => context.go('/acceso'), child: const Text('Ya tengo cuenta')),
      ]),
      const SizedBox(height: 22),
      Wrap(spacing: 20, runSpacing: 8, children: [
        for (final texto in const ['Médicos con credenciales revisadas', 'Historial cifrado'])
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.verde),
            const SizedBox(width: 6),
            Text(texto, style: t.labelLarge?.copyWith(color: AppColors.pizarra)),
          ]),
      ]),
    ]);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: ContenidoCentrado(
        padding: EdgeInsets.fromLTRB(angosto ? 20 : 32, angosto ? 32 : 64, angosto ? 20 : 32, angosto ? 40 : 72),
        child: angosto
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [texto, const SizedBox(height: 36), const _PanelPulso(espacioTrazo: 150)])
            : Row(children: [
                Expanded(flex: 11, child: texto),
                const SizedBox(width: 56),
                const Expanded(flex: 10, child: _PanelPulso(espacioTrazo: 200)),
              ]),
      ),
    );
  }
}

/// Panel azul con el trazo de un pulso y dos fichas que muestran el producto.
class _PanelPulso extends StatefulWidget {
  const _PanelPulso({required this.espacioTrazo});

  /// Alto libre entre la etiqueta superior y las fichas, donde se dibuja el pulso.
  final double espacioTrazo;

  @override
  State<_PanelPulso> createState() => _PanelPulsoState();
}

class _PanelPulsoState extends State<_PanelPulso> with SingleTickerProviderStateMixin {
  late final AnimationController _trazo = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    // Un solo momento orquestado; con «reducir movimiento» el trazo ya aparece completo.
    if (MediaQuery.of(context).disableAnimations) {
      _trazo.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _trazo.forward();
      });
    }
  }

  @override
  void dispose() {
    _trazo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: 'Vista previa de Bewell: próxima consulta confirmada y resumen del expediente',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(color: AppColors.primario, borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _trazo,
              builder: (_, __) => CustomPaint(
                painter: _PintorPulso(
                  progreso: Curves.easeInOutCubic.transform(_trazo.value),
                  base: 52 + widget.espacioTrazo * 0.62,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6EE7B7), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Especialistas con horario hoy', style: t.labelMedium?.copyWith(color: Colors.white)),
                  ]),
                ),
              ),
              SizedBox(height: widget.espacioTrazo),
              _Ficha(
                icono: Icons.folder_shared_outlined,
                titulo: 'Tu expediente',
                cuerpo: Wrap(spacing: 8, runSpacing: 8, children: const [
                  _Dato('Grupo', 'O+'),
                  _Dato('Alergias', 'Penicilina'),
                  _Dato('Tensión', '118/76'),
                ]),
              ),
              const SizedBox(height: 10),
              _Ficha(
                icono: Icons.event_available_rounded,
                titulo: 'Próxima consulta',
                cuerpo: Text('Jueves 10:30 a. m., videollamada con Medicina Interna', style: t.bodyMedium),
                final_: const Icon(Icons.verified_rounded, color: AppColors.verde, size: 22),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.icono, required this.titulo, required this.cuerpo, this.final_});
  final IconData icono;
  final String titulo;
  final Widget cuerpo;
  final Widget? final_;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x290A2540), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(11)),
          child: Icon(icono, color: AppColors.primario, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: t.labelMedium?.copyWith(color: AppColors.pizarraClara)),
            const SizedBox(height: 4),
            cuerpo,
          ]),
        ),
        if (final_ != null) ...[const SizedBox(width: 8), final_!],
      ]),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.lienzo, borderRadius: BorderRadius.circular(8)),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$etiqueta  ', style: t.bodySmall),
        TextSpan(text: valor, style: t.labelLarge),
      ])),
    );
  }
}

/// Trazo de electrocardiograma: rejilla clínica tenue y un latido que se dibuja.
class _PintorPulso extends CustomPainter {
  _PintorPulso({required this.progreso, required this.base});
  final double progreso;
  final double base;

  @override
  void paint(Canvas canvas, Size size) {
    // Rejilla de papel de ECG, apenas visible.
    final rejilla = Paint()
      ..color = Colors.white.withAlpha(18)
      ..strokeWidth = 1;
    const paso = 28.0;
    for (var x = paso; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), rejilla);
    }
    for (var y = paso; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rejilla);
    }

    final w = size.width;
    final ruta = Path()..moveTo(0, base);
    // Dos latidos completos (onda P, complejo QRS, onda T) sobre la línea base.
    void latido(double x0, double ancho) {
      double x(double f) => x0 + ancho * f;
      ruta
        ..lineTo(x(0.10), base)
        ..quadraticBezierTo(x(0.14), base - 12, x(0.18), base)
        ..lineTo(x(0.26), base)
        ..lineTo(x(0.29), base + 10)
        ..lineTo(x(0.34), base - 78)
        ..lineTo(x(0.39), base + 30)
        ..lineTo(x(0.43), base)
        ..lineTo(x(0.54), base)
        ..quadraticBezierTo(x(0.62), base - 22, x(0.70), base)
        ..lineTo(x0 + ancho, base);
    }

    final ancho = math.max(w / 2, 220.0);
    for (var x0 = 0.0; x0 < w; x0 += ancho) {
      latido(x0, ancho);
    }

    final trazo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hecho = Path();
    var punta = Offset.zero;
    for (final m in ruta.computeMetrics()) {
      final largo = m.length * progreso;
      hecho.addPath(m.extractPath(0, largo), Offset.zero);
      punta = m.getTangentForOffset(largo)?.position ?? punta;
    }
    canvas.drawPath(hecho, trazo);
    if (progreso > 0 && progreso < 1) {
      canvas.drawCircle(punta, 5, Paint()..color = Colors.white);
      canvas.drawCircle(punta, 11, Paint()..color = Colors.white.withAlpha(50));
    }
  }

  @override
  bool shouldRepaint(_PintorPulso old) => old.progreso != progreso || old.base != base;
}

/* ─────────────────────────── Garantías ─────────────────────────── */

class _Garantias extends StatelessWidget {
  const _Garantias({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const items = [
      (Icons.verified_user_outlined, 'Médicos verificados', 'Revisamos título, colegiatura y cédula antes de publicar un perfil.'),
      (Icons.history_rounded, 'Tu historial, siempre', 'Consúltalo a cualquier hora y llévalo a cualquier consulta.'),
      (Icons.qr_code_2_rounded, 'Ficha de emergencia', 'Un QR con tus alergias y grupo sanguíneo para paramédicos.'),
      (Icons.draw_outlined, 'Récipes firmados', 'Cada récipe lleva firma digital y la farmacia puede verificarlo.'),
    ];
    final celdas = [
      for (final (icono, titulo, texto) in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icono, color: AppColors.primario, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: t.titleSmall),
                const SizedBox(height: 3),
                Text(texto, style: t.bodySmall?.copyWith(color: AppColors.pizarra, height: 1.45)),
              ]),
            ),
          ]),
        ),
    ];

    return Container(
      color: AppColors.lienzo,
      child: ContenidoCentrado(
        padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: 32),
        child: LayoutBuilder(builder: (context, c) {
          final columnas = c.maxWidth >= 1000 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
          const hueco = 28.0;
          final ancho = (c.maxWidth - hueco * (columnas - 1)) / columnas;
          return Wrap(spacing: hueco, runSpacing: 20, children: [for (final celda in celdas) SizedBox(width: ancho, child: celda)]);
        }),
      ),
    );
  }
}

/* ─────────────────────────── Propósito ─────────────────────────── */

class _Proposito extends StatelessWidget {
  const _Proposito({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cita = Container(
      padding: EdgeInsets.all(angosto ? 28 : 40),
      decoration: BoxDecoration(color: AppColors.marino, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.favorite_rounded, color: Color(0xFF8DB8FF), size: 28),
        const SizedBox(height: 48),
        Text('Hacer que una mejor salud esté al alcance de todos.',
            style: (angosto ? t.headlineMedium : t.headlineLarge)?.copyWith(color: Colors.white)),
        const SizedBox(height: 14),
        Text('Nuestro propósito', style: t.labelLarge?.copyWith(color: Colors.white.withAlpha(170))),
      ]),
    );
    final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Encabezado(
        antetitulo: 'Por qué existe Bewell',
        titulo: 'Atención médica que se adapta a tu vida',
        descripcion: 'Cuidar de tu salud no debería sentirse como un trámite. Reunimos médicos, citas, exámenes y récipes '
            'en un solo lugar, y te damos el control de quién ve tu información.',
      ),
      for (final linea in const [
        'Atención cercana, centrada en cada persona',
        'Acceso simple a profesionales de confianza',
        'Tecnología que acompaña sin complicar',
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            const Icon(Icons.check_rounded, size: 20, color: AppColors.primario),
            const SizedBox(width: 10),
            Expanded(child: Text(linea, style: t.labelLarge?.copyWith(fontSize: 15.5))),
          ]),
        ),
    ]);
    return ContenidoCentrado(
      padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: angosto ? 48 : 88),
      child: angosto
          ? Column(children: [cita, const SizedBox(height: 36), texto])
          : Row(children: [Expanded(child: cita), const SizedBox(width: 64), Expanded(child: texto)]),
    );
  }
}

/* ───────────────────────── Características ───────────────────────── */

class _Caracteristicas extends StatelessWidget {
  const _Caracteristicas({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const items = [
      (
        Icons.calendar_month_outlined,
        'Citas sin vueltas',
        'Ves la disponibilidad real del médico y reservas en tres pasos. Nadie más puede tomar tu horario.'
      ),
      (
        Icons.folder_shared_outlined,
        'Un expediente que viaja contigo',
        'Un único historial, independiente del médico o la clínica. Lo exportas en PDF cuando quieras.'
      ),
      (Icons.admin_panel_settings_outlined, 'Tú das los permisos', 'Eliges qué médico ve cada sección de tu historial y hasta qué fecha.'),
      (Icons.family_restroom_rounded, 'Toda tu familia', 'Administra los perfiles de tus hijos o tus padres desde la misma cuenta.'),
    ];
    return Container(
      color: AppColors.superficie,
      child: ContenidoCentrado(
        padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: angosto ? 8 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Encabezado(antetitulo: 'Todo en un mismo lugar', titulo: 'Tu salud, más simple y conectada'),
          LayoutBuilder(builder: (context, c) {
            final dos = c.maxWidth >= 720;
            final filas = <Widget>[];
            for (var i = 0; i < items.length; i += dos ? 2 : 1) {
              final grupo = items.sublist(i, math.min(i + (dos ? 2 : 1), items.length));
              filas.add(DecoratedBox(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borde))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (var j = 0; j < grupo.length; j++) ...[
                      if (j > 0) const SizedBox(width: 48),
                      Expanded(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(12)),
                            child: Icon(grupo[j].$1, color: AppColors.primario, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(grupo[j].$2, style: t.titleMedium),
                              const SizedBox(height: 6),
                              Text(grupo[j].$3, style: t.bodyMedium?.copyWith(color: AppColors.pizarra, height: 1.55)),
                            ]),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
              ));
            }
            return Column(children: filas);
          }),
        ]),
      ),
    );
  }
}

/* ───────────────────────────── Equipo ───────────────────────────── */

class _Equipo extends StatelessWidget {
  const _Equipo();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 56),
      color: AppColors.marinoProfundo,
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: ContenidoCentrado(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Profesionales que te escuchan', style: t.labelLarge?.copyWith(color: const Color(0xFF8DB8FF))),
            const SizedBox(height: 6),
            Text('Un equipo médico en quien confiar', style: t.headlineLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 32),
            FutureBuilder<List<Medico>>(
              future: sl<BuscarEspecialistas>()(),
              builder: (context, snap) {
                final medicos = (snap.data ?? const <Medico>[]).take(3).toList();
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 96, child: Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)));
                }
                if (medicos.isEmpty) {
                  return Text('Pronto verás aquí a los especialistas verificados.', style: t.bodyLarge?.copyWith(color: Colors.white70));
                }
                return Wrap(spacing: 16, runSpacing: 16, children: [
                  for (final m in medicos)
                    Container(
                      width: 340,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(14),
                        border: Border.all(color: Colors.white.withAlpha(24)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        AvatarIniciales(m.nombreCompleto, radio: 28, verificado: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.nombreCompleto, style: t.titleMedium?.copyWith(color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(m.especialidad, style: t.bodyMedium?.copyWith(color: Colors.white70)),
                          ]),
                        ),
                      ]),
                    ),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

/* ───────────────────────────── Pasos ───────────────────────────── */

class _Pasos extends StatelessWidget {
  const _Pasos({required this.angosto});
  final bool angosto;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const pasos = [
      ('Cuéntanos qué necesitas', 'Elige la especialidad o busca por nombre del médico.'),
      ('Elige a tu especialista', 'Compara perfiles verificados, horarios y modalidad de consulta.'),
      ('Reserva y recibe atención', 'Confirma la cita y recibe el recordatorio antes de la consulta.'),
    ];
    return ContenidoCentrado(
      padding: EdgeInsets.symmetric(horizontal: angosto ? 20 : 32, vertical: angosto ? 56 : 88),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Encabezado(antetitulo: 'Fácil desde el primer paso', titulo: 'Tu primera cita en tres pasos'),
        LayoutBuilder(builder: (context, c) {
          final enFila = c.maxWidth >= 760;
          final celdas = [
            for (var i = 0; i < pasos.length; i++)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primario, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: t.titleSmall?.copyWith(color: Colors.white)),
                  ),
                  if (enFila && i < pasos.length - 1) ...[
                    const SizedBox(width: 12),
                    const Expanded(child: Divider(color: AppColors.bordeFuerte)),
                    const SizedBox(width: 12),
                  ],
                ]),
                const SizedBox(height: 16),
                Text(pasos[i].$1, style: t.titleLarge),
                const SizedBox(height: 6),
                Text(pasos[i].$2, style: t.bodyMedium?.copyWith(color: AppColors.pizarra, height: 1.55)),
              ]),
          ];
          if (!enFila) {
            return Column(children: [
              for (final celda in celdas) Padding(padding: const EdgeInsets.only(bottom: 28), child: celda),
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final celda in celdas) Expanded(child: Padding(padding: const EdgeInsets.only(right: 28), child: celda)),
          ]);
        }),
      ]),
    );
  }
}

/* ──────────────────────── Llamado y pie ──────────────────────── */

class _Llamado extends StatelessWidget {
  const _Llamado();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ContenidoCentrado(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
        decoration: BoxDecoration(color: AppColors.primario, borderRadius: BorderRadius.circular(28)),
        child: Column(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(children: [
              Text('Tu bienestar empieza con una conversación',
                  textAlign: TextAlign.center, style: t.headlineLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 12),
              Text('Encuentra al especialista que necesitas y reserva tu consulta hoy.',
                  textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: Colors.white.withAlpha(215))),
            ]),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primarioOscuro),
            onPressed: () => context.go('/acceso?registro=1'),
            child: const Text('Reservar mi cita'),
          ),
        ]),
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.alLogo});
  final VoidCallback alLogo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 64),
      color: AppColors.marinoProfundo,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: ContenidoCentrado(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              BwLogo(claro: true, tamano: 28, alPulsar: alLogo),
              Text('© 2026 Bewell. Cuidando de ti, estés donde estés.', style: t.bodySmall?.copyWith(color: Colors.white70)),
              Wrap(spacing: 4, children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF8DB8FF)),
                  onPressed: () => context.go('/verificar'),
                  child: const Text('Verificar récipe'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF8DB8FF)),
                  onPressed: () => context.go('/acceso'),
                  child: const Text('Iniciar sesión'),
                ),
              ]),
            ]),
      ),
    );
  }
}
