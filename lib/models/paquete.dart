import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaquetesDelDiaScreen extends StatelessWidget {
  const PaquetesDelDiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fechaHoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paquetes del día'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('paquetes_entradas')
            .where('fecha', isEqualTo: fechaHoy)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay paquetes registrados hoy',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              _header(fechaHoy, docs.length),
              const Divider(),

              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return _filaPaquete(data, index + 1);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===== ENCABEZADO =====
  Widget _header(String fecha, int total) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Fecha: $fecha',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            'Total: $total',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ===== FILA TIPO TABLA =====
  Widget _filaPaquete(Map<String, dynamic> data, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Nº
          SizedBox(
            width: 30,
            child: Text(
              '$index',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Código
          Expanded(
            flex: 3,
            child: Text(
              data['codigo'] ?? '---',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Hora
          Expanded(
            flex: 2,
            child: Text(
              data['hora'] ?? '--:--',
              style: const TextStyle(color: Colors.black54),
            ),
          ),

          // Usuario
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['usuario']?['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  data['usuario']?['rol'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
