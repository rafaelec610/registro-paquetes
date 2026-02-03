import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialPaquetesScreen extends StatelessWidget {
  const HistorialPaquetesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fechaHoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes del día'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('paquetes_entradas')
            .where('fecha', isEqualTo: fechaHoy)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar datos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final paquetes = snapshot.data!.docs;

          if (paquetes.isEmpty) {
            return const Center(
              child: Text(
                'No hay paquetes registrados hoy',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: paquetes.length,
            itemBuilder: (context, index) {
              final data = paquetes[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.green),
                  title: Text(
                    data['codigo'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hora: ${data['hora']}"),
                      Text("Usuario: ${data['usuario']['nombre']}"),
                      Text("Rol: ${data['usuario']['rol']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _verDetalle(context, data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _verDetalle(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalle del paquete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Código: ${data['codigo']}"),
            Text("Fecha: ${data['fecha']}"),
            Text("Hora: ${data['hora']}"),
            const SizedBox(height: 10),
            Text("Usuario: ${data['usuario']['nombre']}"),
            Text("Rol: ${data['usuario']['rol']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
