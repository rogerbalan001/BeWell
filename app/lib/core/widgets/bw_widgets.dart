import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatos.dart';

/// Logotipo de Bewell (corazón en un cuadro azul + palabra).
class BwLogo extends StatelessWidget {
  const BwLogo({super.key, this.claro = false, this.tamano = 36});
  final bool claro;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(color: AppColors.primario, borderRadius: BorderRadius.circular(tamano * 0.3)),
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: tamano * 0.55),
      ),
      const SizedBox(width: 10),
      Text.rich(TextSpan(children: [
        TextSpan(text: 'Be', style: TextStyle(color: claro ? Colors.white : AppColors.marino)),
        const TextSpan(text: 'well', style: TextStyle(color: AppColors.primario)),
      ]), style: TextStyle(fontSize: tamano * 0.6, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
    ]);
  }
}

/// Tarjeta blanca con borde azul tenue y esquinas de 24 px.
class BwTarjeta extends StatelessWidget {
  const BwTarjeta({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color, this.onTap, this.borde});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final contenido = Padding(padding: padding, child: child);
    return Material(
      color: color ?? AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borde ?? AppColors.bordeAzul),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? contenido : InkWell(onTap: onTap, child: contenido),
    );
  }
}

/// Píldora de estado con punto de color ("Disponible hoy", "Confirmada"…).
class ChipEstado extends StatelessWidget {
  const ChipEstado(this.texto, {super.key, this.color = AppColors.verde, this.fondo, this.icono});
  final String texto;
  final Color color;
  final Color? fondo;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fondo ?? color.withAlpha(28), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icono != null)
          Icon(icono, size: 13, color: color)
        else
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales(this.nombre, {super.key, this.radio = 24, this.verificado = false});
  final String nombre;
  final double radio;
  final bool verificado;

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(
        radius: radio,
        backgroundColor: AppColors.azulSuave,
        child: Text(Formatos.iniciales(nombre),
            style: TextStyle(color: AppColors.primarioOscuro, fontWeight: FontWeight.w800, fontSize: radio * 0.7)),
      ),
      if (verificado)
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            padding: const EdgeInsets.all(1.5),
            child: Icon(Icons.verified_rounded, color: AppColors.verde, size: radio * 0.6),
          ),
        ),
    ]);
  }
}

/// Encabezado de página con antetítulo en mayúsculas (eyebrow).
class Encabezado extends StatelessWidget {
  const Encabezado({super.key, this.antetitulo, required this.titulo, this.descripcion, this.accion});
  final String? antetitulo;
  final String titulo;
  final String? descripcion;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final textos = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (antetitulo != null)
        Text(antetitulo!.toUpperCase(),
            style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.4)),
      if (antetitulo != null) const SizedBox(height: 6),
      Text(titulo, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6)),
      if (descripcion != null) ...[
        const SizedBox(height: 6),
        Text(descripcion!, style: t.bodyMedium?.copyWith(color: AppColors.pizarra, height: 1.5)),
      ],
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: accion == null
          ? textos
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 12,
              spacing: 12,
              children: [textos, accion!],
            ),
    );
  }
}

/// Tarjeta con título y subtítulo de sección.
class SeccionTarjeta extends StatelessWidget {
  const SeccionTarjeta({super.key, required this.titulo, this.subtitulo, required this.child, this.accion, this.icono});
  final String titulo;
  final String? subtitulo;
  final Widget child;
  final Widget? accion;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return BwTarjeta(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icono != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(12)),
              child: Icon(icono, color: AppColors.primario, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              if (subtitulo != null)
                Text(subtitulo!, style: const TextStyle(color: AppColors.pizarraClara, fontSize: 13)),
            ]),
          ),
          if (accion != null) accion!,
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class VistaCargando extends StatelessWidget {
  const VistaCargando({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
}

class VistaError extends StatelessWidget {
  const VistaError(this.mensaje, {super.key, this.reintentar});
  final String mensaje;
  final VoidCallback? reintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.pizarraClara),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.pizarra)),
          if (reintentar != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: reintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ]),
      ),
    );
  }
}

class VistaVacia extends StatelessWidget {
  const VistaVacia({super.key, required this.icono, required this.titulo, this.mensaje, this.accion});
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.superficieAzul2, shape: BoxShape.circle),
            child: Icon(icono, size: 34, color: AppColors.primario),
          ),
          const SizedBox(height: 14),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (mensaje != null) ...[
            const SizedBox(height: 6),
            Text(mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.pizarra)),
          ],
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ]),
      ),
    );
  }
}

/// Indicador de pasos del flujo de reserva (Especialista → Horario → Confirmación).
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.pasos, required this.actual});
  final List<String> pasos;
  final int actual;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < pasos.length; i++) ...[
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: i <= actual ? AppColors.primario : AppColors.superficieAzul2,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(height: 6),
            Text('${i + 1}. ${pasos[i]}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: i == actual ? FontWeight.w700 : FontWeight.w500,
                  color: i <= actual ? AppColors.primario : AppColors.pizarraClara,
                )),
          ]),
        ),
        if (i < pasos.length - 1) const SizedBox(width: 8),
      ],
    ]);
  }
}

/// Contenedor centrado con ancho máximo de 1180 px (rejilla de escritorio del diseño).
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({super.key, required this.child, this.maxAncho = 1180, this.padding});
  final Widget child;
  final double maxAncho;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxAncho),
        child: Padding(padding: padding ?? EdgeInsets.symmetric(horizontal: ancho < 600 ? 16 : 28, vertical: 24), child: child),
      ),
    );
  }
}

/// Fila etiqueta / valor para resúmenes.
class FilaDato extends StatelessWidget {
  const FilaDato(this.etiqueta, this.valor, {super.key, this.destacado = false, this.icono});
  final String etiqueta;
  final String valor;
  final bool destacado;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icono != null) ...[Icon(icono, size: 18, color: AppColors.primario), const SizedBox(width: 10)],
        Expanded(child: Text(etiqueta, style: const TextStyle(color: AppColors.pizarra, fontSize: 14))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: destacado ? FontWeight.w800 : FontWeight.w600,
                fontSize: destacado ? 18 : 14,
                color: destacado ? AppColors.primario : AppColors.marino,
              )),
        ),
      ]),
    );
  }
}

void mostrarMensaje(BuildContext context, String mensaje, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mensaje),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.error : AppColors.marino,
    ));
}

Future<bool> confirmar(BuildContext context, {required String titulo, required String mensaje, String accion = 'Confirmar', bool peligro = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
        FilledButton(
          style: peligro ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Pide un texto en un diálogo (motivo de cancelación, de rechazo, etc.).
Future<String?> pedirTexto(BuildContext context, {required String titulo, required String etiqueta, String accion = 'Enviar'}) async {
  final controlador = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(controller: controlador, maxLines: 3, autofocus: true, decoration: InputDecoration(labelText: etiqueta)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controlador.text.trim()), child: Text(accion)),
      ],
    ),
  );
  return (r == null || r.isEmpty) ? null : r;
}
