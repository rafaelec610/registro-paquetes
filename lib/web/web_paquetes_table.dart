import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WebPaquetesTable extends StatelessWidget {
  const WebPaquetesTable({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('historial_paquetes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Usuario')),
              DataColumn(label: Text('Rol')),
              DataColumn(label: Text('Evidencia')),
            ],
            rows: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final fecha = data['timestamp']?.toDate();

              return DataRow(cells: [
                DataCell(Text(data['codigo'] ?? '')),
                DataCell(Text(data['estado'] ?? '')),
                DataCell(Text(
                  fecha != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(fecha)
                      : '',
                )),
                DataCell(Text(data['usuario'] ?? '')),
                DataCell(Text(data['rol'] ?? '')),
                DataCell(
                  data['foto'] != null
                      ? IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: Image.network(data['foto']),
                              ),
                            );
                          },
                        )
                      : const Text('—'),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}
