import 'package:flutter/material.dart';

import '../../../../core/widgets/bw_widgets.dart';

/// Pantalla breve mientras se restaura la sesión guardada.
class CargandoPage extends StatelessWidget {
  const CargandoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BwLogo(tamano: 48),
          SizedBox(height: 24),
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
        ]),
      ),
    );
  }
}
