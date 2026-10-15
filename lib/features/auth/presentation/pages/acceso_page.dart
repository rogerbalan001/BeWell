import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/bw_widgets.dart';
import '../../domain/entities/usuario_sesion.dart';
import '../cubit/sesion_cubit.dart';

/// Pantalla "Iniciar sesión y registro" (diseño Stitch).
class AccesoPage extends StatefulWidget {
  const AccesoPage({super.key, this.registro = false});
  final bool registro;

  @override
  State<AccesoPage> createState() => _AccesoPageState();
}

class _AccesoPageState extends State<AccesoPage> {
  late bool _registro = widget.registro;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final formulario = BwTarjeta(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Crear cuenta'), icon: Icon(Icons.person_add_alt_1)),
            ButtonSegment(value: false, label: Text('Iniciar sesión'), icon: Icon(Icons.login)),
          ],
          selected: {_registro},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _registro = s.first),
        ),
        const SizedBox(height: 24),
        if (_registro) const _FormularioRegistro() else const _FormularioLogin(),
      ]),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const BwLogo(tamano: 32),
        actions: [TextButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.arrow_back), label: const Text('Volver al inicio'))],
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: AppColors.superficieAzul2, borderRadius: BorderRadius.circular(14)),
              child: const Wrap(spacing: 18, runSpacing: 6, children: [
                ChipEstado('Cifrado AES-256 de datos clínicos', icono: Icons.lock_outline, color: AppColors.verdeOscuro),
                ChipEstado('Tú decides qué médico ve tu historial', icono: Icons.verified_user_outlined, color: AppColors.primario),
              ]),
            ),
            const SizedBox(height: 24),
            if (ancho >= 980)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Expanded(flex: 5, child: _PanelMarca()),
                const SizedBox(width: 32),
                Expanded(flex: 6, child: formulario),
              ])
            else
              formulario,
          ]),
        ),
      ),
    );
  }
}

class _PanelMarca extends StatelessWidget {
  const _PanelMarca();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.marino, Color(0xFF16345C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ChipEstado('RED CLÍNICA CERTIFICADA', color: Colors.white, fondo: Color(0x26FFFFFF), icono: Icons.shield_outlined),
        const SizedBox(height: 24),
        const Text('Tu salud y la de tu familia en un entorno seguro y conectado.',
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.6)),
        const SizedBox(height: 16),
        const Text(
          'Expediente clínico que viaja contigo, récipes verificables y una ficha de emergencia con código QR. '
          'Solo tú decides quién ve tu historial y por cuánto tiempo.',
          style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 28),
        for (final (icono, titulo, texto) in const [
          (Icons.event_available, 'Citas en minutos', 'Elige especialista, fecha y modalidad.'),
          (Icons.receipt_long, 'Récipes con firma digital', 'Válidos en cualquier farmacia con su código QR.'),
          (Icons.qr_code_2, 'Pase médico de emergencia', 'Alergias y grupo sanguíneo sin desbloquear tu teléfono.'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(14)),
                child: Icon(icono, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(texto, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _FormularioLogin extends StatefulWidget {
  const _FormularioLogin();
  @override
  State<_FormularioLogin> createState() => _FormularioLoginState();
}

class _FormularioLoginState extends State<_FormularioLogin> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _enviando = false;
  bool _oculta = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final error = await context.read<SesionCubit>().iniciarSesion(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) mostrarMensaje(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Bienvenido de vuelta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Ingresa con tu correo registrado.', style: TextStyle(color: AppColors.pizarra)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: AppTheme.campo('Correo electrónico', icono: Icons.mail_outline),
          validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _password,
          obscureText: _oculta,
          onFieldSubmitted: (_) => _enviar(),
          decoration: AppTheme.campo('Contraseña', icono: Icons.key_outlined).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_oculta ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _oculta = !_oculta),
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _enviando ? null : _enviar,
          icon: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.arrow_forward),
          label: const Text('Iniciar sesión'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.superficieAzul, borderRadius: BorderRadius.circular(14)),
          child: const Text(
            'Cuentas de demostración (contraseña Bewell2026!): sofia.morales@bewell.app · mateo.ruiz@bewell.app · '
            'admin@bewell.app · emergencia@bewell.app',
            style: TextStyle(fontSize: 12.5, color: AppColors.pizarra, height: 1.5),
          ),
        ),
      ]),
    );
  }
}

class _FormularioRegistro extends StatefulWidget {
  const _FormularioRegistro();
  @override
  State<_FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<_FormularioRegistro> {
  final _form = GlobalKey<FormState>();
  bool _esMedico = false;
  bool _enviando = false;
  bool _acepta = false;
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _cedula = TextEditingController();
  final _especialidad = TextEditingController();
  final _tarifa = TextEditingController(text: '45');
  DateTime? _nacimiento;
  String _sexo = 'F';

  static const _especialidades = ['Medicina General', 'Medicina Interna', 'Cardiología', 'Pediatría', 'Dermatología', 'Ginecología'];

  @override
  void dispose() {
    for (final c in [_nombres, _apellidos, _email, _telefono, _password, _cedula, _especialidad, _tarifa]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _fuerza {
    final p = _password.text;
    return [p.length >= 8, RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p), RegExp(r'[^A-Za-z0-9]').hasMatch(p)]
        .where((x) => x)
        .length;
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _nacimiento ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
    );
    if (f != null) setState(() => _nacimiento = f);
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    if (!_esMedico && _nacimiento == null) {
      mostrarMensaje(context, 'Indica tu fecha de nacimiento', error: true);
      return;
    }
    if (!_acepta) {
      mostrarMensaje(context, 'Debes aceptar el tratamiento seguro de datos de salud', error: true);
      return;
    }
    setState(() => _enviando = true);
    final sesion = context.read<SesionCubit>();
    final error = _esMedico
        ? await sesion.registrarMedico(DatosRegistroMedico(
            email: _email.text.trim(),
            password: _password.text,
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            especialidad: _especialidad.text.trim(),
            tarifaConsulta: double.tryParse(_tarifa.text.replaceAll(',', '.')) ?? 0,
            telefono: _telefono.text.trim(),
          ))
        : await sesion.registrarPaciente(DatosRegistroPaciente(
            email: _email.text.trim(),
            password: _password.text,
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            fechaNacimiento: _nacimiento!,
            sexo: _sexo,
            cedula: _cedula.text.trim(),
            telefono: _telefono.text.trim(),
          ));
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) mostrarMensaje(context, error, error: true);
  }

  Widget _tipoCuenta(bool medico, IconData icono, String titulo, String texto) {
    final activo = _esMedico == medico;
    return Expanded(
      child: BwTarjeta(
        color: activo ? AppColors.superficieAzul2 : AppColors.superficieAzul,
        borde: activo ? AppColors.primario : Colors.transparent,
        padding: const EdgeInsets.all(16),
        onTap: () => setState(() => _esMedico = medico),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: activo ? AppColors.primario : Colors.white,
              child: Icon(icono, color: activo ? Colors.white : AppColors.pizarra),
            ),
            const Spacer(),
            if (activo) const Icon(Icons.check_circle, color: AppColors.primario),
          ]),
          const SizedBox(height: 10),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(texto, style: const TextStyle(color: AppColors.pizarra, fontSize: 12.5, height: 1.4)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fuerza = _fuerza;
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Bienvenido a Bewell', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Selecciona tu tipo de perfil para configurar tu espacio seguro.', style: TextStyle(color: AppColors.pizarra)),
        const SizedBox(height: 18),
        Row(children: [
          _tipoCuenta(false, Icons.favorite_rounded, 'Paciente / Usuario', 'Gestiona citas, tu familia y sé el único dueño de tu expediente.'),
          const SizedBox(width: 12),
          _tipoCuenta(true, Icons.medical_services_outlined, 'Profesional médico', 'Publica horarios y atiende. Requiere verificación de credenciales.'),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _nombres,
              decoration: AppTheme.campo('Nombres', icono: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _apellidos,
              decoration: AppTheme.campo('Apellidos'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: AppTheme.campo('Correo electrónico', icono: Icons.mail_outline),
          validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Correo inválido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _telefono, keyboardType: TextInputType.phone, decoration: AppTheme.campo('Teléfono móvil', icono: Icons.phone_iphone)),
        const SizedBox(height: 12),
        if (!_esMedico) ...[
          Row(children: [
            Expanded(child: TextFormField(controller: _cedula, decoration: AppTheme.campo('Cédula (opcional)', icono: Icons.badge_outlined))),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.cake_outlined),
                label: Text(_nacimiento == null ? 'Fecha de nacimiento' : Formatos.fechaCorta(_nacimiento!)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final (valor, etiqueta) in const [('F', 'Femenino'), ('M', 'Masculino'), ('OTRO', 'Otro')])
              ChoiceChip(label: Text(etiqueta), selected: _sexo == valor, onSelected: (_) => setState(() => _sexo = valor)),
          ]),
        ] else ...[
          TextFormField(
            controller: _especialidad,
            decoration: AppTheme.campo('Especialidad', icono: Icons.local_hospital_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in _especialidades)
              ActionChip(label: Text(e, style: const TextStyle(fontSize: 12)), onPressed: () => setState(() => _especialidad.text = e)),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tarifa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: AppTheme.campo('Tarifa por consulta', icono: Icons.attach_money, sufijo: 'USD'),
            validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Tarifa inválida' : null,
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _password,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: AppTheme.campo('Contraseña segura', icono: Icons.key_outlined, ayuda: 'Mínimo 8 caracteres, con letras y números'),
          validator: (v) {
            final p = v ?? '';
            if (p.length < 8) return 'Mínimo 8 caracteres';
            if (!RegExp(r'[A-Za-z]').hasMatch(p) || !RegExp(r'\d').hasMatch(p)) return 'Combina letras y números';
            return null;
          },
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fuerza / 3,
          minHeight: 6,
          borderRadius: BorderRadius.circular(9),
          color: fuerza >= 3 ? AppColors.verde : (fuerza == 2 ? AppColors.primario : AppColors.ambar),
          backgroundColor: AppColors.superficieAzul2,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _acepta,
          onChanged: (v) => setState(() => _acepta = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Acepto el tratamiento seguro de mis datos de salud y los términos de servicio.', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _enviando ? null : _enviar,
          icon: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.arrow_forward),
          label: Text(_esMedico ? 'Crear cuenta como médico' : 'Crear cuenta como paciente'),
        ),
      ]),
    );
  }
}
