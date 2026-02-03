import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodosLosPaquetesScreen extends StatefulWidget {
  const TodosLosPaquetesScreen({super.key});

  @override
  State<TodosLosPaquetesScreen> createState() =>
      _TodosLosPaquetesScreenState();
}

class _TodosLosPaquetesScreenState extends State<TodosLosPaquetesScreen> {
  String _searchText = '';

  int _calcularDias(Timestamp timestamp) {
    final fechaRegistro = timestamp.toDate();
    return DateTime.now().difference(fechaRegistro).inDays;
  }

  Color _colorPorDias(int dias) {
    if (dias <= 2) return Colors.green;
    if (dias <= 4) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los paquetes'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // 🔍 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por código',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toUpperCase();
                });
              },
            ),
          ),

          // 📦 LISTADO
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('paquetes_entradas')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al cargar paquetes'));
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final codigo =
                      (doc['codigo'] ?? '').toString().toUpperCase();
                  return codigo.contains(_searchText);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron paquetes'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final Timestamp timestamp = data['timestamp'];
                    final dias = _calcularDias(timestamp);
                    final color = _colorPorDias(dias);

                    final fecha = DateFormat('dd/MM/yyyy HH:mm')
                        .format(timestamp.toDate());

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.inventory_2,
                          size: 36,
                          color: color,
                        ),
                        title: Text(
                          data['codigo'] ?? 'SIN CÓDIGO',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Usuario: ${data['usuario']}'),
                            Text('Rol: ${data['rol']}'),
                            Text('Fecha: $fecha'),
                            Text(
                              'Días en sistema: $dias',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
