import 'package:flutter/material.dart';

class CuadreDiarioScreen extends StatelessWidget {
  const CuadreDiarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuadre Diario')),
      body: const Center(child: Text('Resumen de operaciones')),
    );
  }
}
